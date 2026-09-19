#!/usr/bin/env node
import fs from "node:fs";
import process from "node:process";

import { DeckSocket } from "./deck-socket.js";
import { send, watch, NotRunningError } from "./vendor/client.js";

/**
 * An OpenDeck plugin for OpenLens.
 *
 * Two connections, in opposite directions. OpenDeck tells us which keys exist
 * and when one is pressed; OpenLens tells us what is true right now. The whole
 * plugin is the join between them: a press becomes a command, and a change
 * becomes a repaint of every key that shows it.
 *
 * That second half is the point. Scenes also change from the ⌃⌥1…⌃⌥9 hotkeys and
 * from the app window, and a key that only knew what it last sent would sit
 * there lying about it.
 *
 * The same file runs on OpenDeck and on an Elgato Stream Deck. OpenDeck runs it
 * with the system `node`, Stream Deck with the one it bundles; both speak the
 * same protocol, so the only thing that differs is the manifest beside it.
 * There are no dependencies, so there is nothing to install and nothing to
 * build.
 */

const args = process.argv.slice(2);
const argument = (flag) => args[args.indexOf(flag) + 1];

const port = argument("-port");
const pluginUUID = argument("-pluginUUID");
const registerEvent = argument("-registerEvent");

const pluginVersion = (() => {
    try {
        return JSON.parse(fs.readFileSync(new URL("./manifest.json", import.meta.url), "utf8")).Version;
    } catch {
        return "unknown";
    }
})();

/** Every key of ours currently on a device, by context. */
const keys = new Map();

/** The last state OpenLens sent, or null while it is not running. */
let camera = null;

let deck;

// MARK: - OpenDeck

function connectToDeck() {
    deck = new DeckSocket(`ws://127.0.0.1:${port}`);

    deck.addEventListener("open", () => {
        deck.send(JSON.stringify({ event: registerEvent, uuid: pluginUUID }));
        // The deck app runs a copy made by install.sh, which goes stale
        // silently; a copy from before a fix once crashed on every login.
        // Naming the version up front makes an old copy visible in the log.
        log(`plugin ${pluginVersion} started`);
    });

    deck.addEventListener("message", ({ data }) => {
        let message;
        try {
            message = JSON.parse(data);
        } catch {
            return;
        }
        handle(message);
    });

    // OpenDeck kills the plugin when it unloads it, so a closed socket means we
    // are on our way out rather than that we should try again.
    deck.addEventListener("close", () => process.exit(0));
    deck.addEventListener("error", () => process.exit(1));
}

function toDeck(event, context, payload) {
    if (deck?.readyState !== DeckSocket.OPEN) return;
    deck.send(JSON.stringify(payload ? { event, context, payload } : { event, context }));
}

function handle(message) {
    const { event, context, action, payload } = message;
    switch (event) {
        case "willAppear":
            keys.set(context, { action, settings: payload?.settings ?? {} });
            render(context);
            break;

        case "willDisappear":
            keys.delete(context);
            break;

        case "didReceiveSettings":
            if (keys.has(context)) keys.get(context).settings = payload?.settings ?? {};
            render(context);
            break;

        case "keyDown":
            // A press carries the key's stored settings; trusting them over a
            // copy from when the key appeared means a change always applies.
            if (payload?.settings && keys.has(context)) keys.get(context).settings = payload.settings;
            press(context).catch((error) => {
                // A refusal is worth showing on the key itself: the person
                // pressing it is looking at the device, not at a log file.
                toDeck("showAlert", context);
                log(error instanceof NotRunningError ? "OpenLens is not running" : error.message);
            });
            break;

        case "sendToPlugin":
            // The inspector passes changed settings straight through, because
            // not every deck app forwards them on its own.
            if (payload?.settings) {
                if (keys.has(context)) keys.get(context).settings = payload.settings;
                render(context);
                break;
            }
        // falls through
        case "propertyInspectorDidAppear":
            // Both mean the same thing to us: an inspector is open and wants
            // the list it cannot know by itself.
            toDeck("sendToPropertyInspector", context, {
                scenes: (camera?.scenes ?? []).map((scene) => ({
                    value: scene.id,
                    label: `${scene.index}. ${scene.name}`,
                })),
                lights: (camera?.lights ?? []).map((light) => ({
                    value: light.serialNumber,
                    label: light.name,
                })),
                running: camera !== null,
            });
            break;
    }
}

function log(message) {
    if (deck?.readyState === DeckSocket.OPEN) {
        deck.send(JSON.stringify({ event: "logMessage", payload: { message: `OpenLens: ${message}` } }));
    }
}

// MARK: - Presses

async function press(context) {
    const key = keys.get(context);
    if (!key) return;
    const settings = key.settings;

    switch (key.action) {
        case "com.trsdn.openlens.scene": {
            // Falling back to stepping means a freshly dropped key does
            // something sensible before anyone opens its settings.
            if (!settings.sceneId) {
                await send("scene.next");
                break;
            }
            // Pressing the live scene again has nothing to switch to, so it
            // pauses instead — and a further press resumes.
            const live = (camera?.scenes ?? []).some(
                (scene) => scene.id === settings.sceneId && scene.isSelected
            );
            if (live) await send("pause.toggle");
            else await send("scene.select", { id: settings.sceneId });
            break;
        }

        case "com.trsdn.openlens.pause":
            await send("pause.toggle");
            break;

        case "com.trsdn.openlens.light":
            await send("light.set", { serialNumber: serialFor(settings), on: !lightFor(settings)?.on });
            break;

        case "com.trsdn.openlens.brightness": {
            const light = lightFor(settings);
            const step = Number(settings.step ?? 0);
            const brightness = step
                ? clamp((light?.brightness ?? 0) + step, 0, 100)
                : clamp(Number(settings.brightness ?? 50), 0, 100);
            await send("light.set", { serialNumber: serialFor(settings), brightness });
            break;
        }

        case "com.trsdn.openlens.zoom":
            await send(
                { in: "zoom.in", out: "zoom.out", reset: "zoom.reset" }[settings.direction] ?? "zoom.reset"
            );
            break;
    }
}

/** The light a key is bound to, or the only one there is when it is bound to none. */
function lightFor(settings) {
    const lights = camera?.lights ?? [];
    if (!settings.serialNumber) return lights.length === 1 ? lights[0] : undefined;
    return lights.find((light) => light.serialNumber === settings.serialNumber);
}

/**
 * The serial number to send.
 *
 * A key left on "the only one found" carries an empty setting, and the app
 * rejects that rather than guessing — so resolve it here, where the light list
 * is known, and say something useful when it cannot be resolved.
 */
function serialFor(settings) {
    const serial = lightFor(settings)?.serialNumber;
    if (serial) return serial;
    throw new Error(
        settings.serialNumber
            ? `No key light with serial number ${settings.serialNumber}`
            : "There is more than one key light, so this key needs to say which one"
    );
}

const clamp = (value, low, high) => Math.min(high, Math.max(low, value));

/**
 * The part of a light's name that tells it apart from the others.
 *
 * Two lights called "Studio links" and "Studio rechts" would both read
 * "Studio" on a narrow key, which is exactly the half that does not help, so
 * the words every light shares at the front are dropped.
 */
function shortName(light) {
    const names = (camera?.lights ?? []).map((other) => other.name.split(/\s+/));
    const words = light.name.split(/\s+/);
    let shared = 0;
    if (names.length > 1) {
        while (shared < words.length - 1 && names.every((other) => other[shared] === words[shared])) {
            shared += 1;
        }
    }
    const rest = words.slice(shared).join(" ");
    return rest.charAt(0).toUpperCase() + rest.slice(1);
}

// MARK: - Painting

/** Icons a key swaps to by its settings, as data URLs both deck apps accept. */
const icons = Object.fromEntries(
    ["zoom-in", "zoom-out", "zoom-reset", "brightness-up", "brightness-down", "brightness"].map((name) => [
        name,
        "data:image/svg+xml;base64," +
            fs.readFileSync(new URL(`./icons/${name}.svg`, import.meta.url)).toString("base64"),
    ])
);

/** Sends an image only when it differs from the key's last one; state pushes are frequent. */
function setImage(context, name) {
    const key = keys.get(context);
    if (!key || key.image === name) return;
    key.image = name;
    toDeck("setImage", context, { image: icons[name] });
}

function zoomIcon(settings) {
    return { in: "zoom-in", out: "zoom-out" }[settings.direction] ?? "zoom-reset";
}

function brightnessIcon(settings) {
    const step = Number(settings.step ?? 0);
    return step > 0 ? "brightness-up" : step < 0 ? "brightness-down" : "brightness";
}

function render(context) {
    const key = keys.get(context);
    if (!key) return;

    // The picture depends only on the key's own settings, so it is right even
    // while the app is away.
    if (key.action === "com.trsdn.openlens.zoom") setImage(context, zoomIcon(key.settings));
    if (key.action === "com.trsdn.openlens.brightness") setImage(context, brightnessIcon(key.settings));

    const template = titleTemplate(key);

    // Rather than blank keys: the labels stay, so the layout still reads as
    // something that will work once the app is back.
    if (!camera) {
        toDeck("setState", context, { state: 0 });
        if (template !== null) toDeck("setTitle", context, { title: template === "" ? "" : "—" });
        return;
    }

    const settings = key.settings;
    const current = camera.scene;
    const values = {
        zoom: `${(camera.zoom ?? 1).toFixed(1)}×`,
        scene: current?.name ?? "?",
        index: current?.index ?? "?",
    };

    switch (key.action) {
        case "com.trsdn.openlens.scene": {
            const scene =
                (camera.scenes ?? []).find((candidate) => candidate.id === settings.sceneId) ??
                (settings.sceneId ? undefined : camera.scene);
            toDeck("setState", context, { state: scene?.isSelected ? 1 : 0 });
            values.scene = scene?.name ?? "?";
            values.index = scene?.index ?? "?";
            break;
        }

        case "com.trsdn.openlens.pause":
            toDeck("setState", context, { state: camera.paused ? 1 : 0 });
            break;

        case "com.trsdn.openlens.light": {
            const light = lightFor(settings);
            toDeck("setState", context, { state: light?.on ? 1 : 0 });
            Object.assign(values, lightValues(light));
            break;
        }

        case "com.trsdn.openlens.brightness":
            Object.assign(values, lightValues(lightFor(settings)), {
                target: clamp(Number(settings.brightness ?? 50), 0, 100),
            });
            break;
    }

    if (template !== null) toDeck("setTitle", context, { title: fillTemplate(template, values) });
}

/**
 * What a key's label should say before its placeholders are filled in, or
 * null to leave the title the deck app itself shows alone.
 *
 * A switched-off label is an empty string rather than null: the plugin set a
 * title before, and only an explicit empty one clears it.
 */
function titleTemplate(key) {
    const settings = key.settings;
    if (settings.showTitle === false) return "";
    if (typeof settings.title === "string" && settings.title.trim()) return settings.title;
    switch (key.action) {
        case "com.trsdn.openlens.scene":
            return "{scene}";
        case "com.trsdn.openlens.light":
            return "{light}";
        case "com.trsdn.openlens.brightness":
            // A stepping key's direction is in its picture; a fixed one says
            // what it will set.
            return Number(settings.step ?? 0) ? "{light}" : "{light}\\n{target}%";
        case "com.trsdn.openlens.zoom":
            return "{zoom}";
        default:
            return null;
    }
}

function lightValues(light) {
    return light
        ? { light: shortName(light), name: light.name, brightness: light.brightness, kelvin: light.kelvin }
        : { light: "?", name: "?", brightness: "?", kelvin: "?" };
}

/** `\n` typed in a one-line field becomes a line break; unknown placeholders stay as typed. */
function fillTemplate(template, values) {
    return template
        .replace(/\\n/g, "\n")
        .replace(/\{(\w+)\}/g, (match, name) => (name in values ? String(values[name]) : match));
}

const renderAll = () => {
    for (const context of keys.keys()) render(context);
};

// MARK: - OpenLens

connectToDeck();

watch(
    (state) => {
        camera = state;
        renderAll();
    },
    {
        onError: (error) => log(error.message),
        onDisconnect: () => {
            camera = null;
            renderAll();
        },
    }
);
