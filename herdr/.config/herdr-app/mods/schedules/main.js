import { View, div } from "gpui-kit";
import { v_flex, h_flex, InputState, Input, TextareaState, Textarea } from "gpui-base";
import {
  appHome,
  exec,
  hc,
  home,
  knownAgents,
  notify,
  pickFolder,
  readTextFile,
  run,
  theme,
  window,
  writeTextFile,
} from "herdr";

const STORE = "schedules.v1";
const CADENCES = [
  { id: "minutes", label: "Minutes" },
  { id: "hourly", label: "Hourly" },
  { id: "daily", label: "Daily" },
  { id: "weekdays", label: "Weekdays" },
  { id: "weekly", label: "Weekly" },
];

const safeId = () => `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
const shQuote = (value) => `'${String(value).replace(/'/g, `'\\''`)}'`;
const xml = (value) => String(value).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
const unitQuote = (value) => `"${String(value).replace(/%/g, "%%").replace(/\\/g, "\\\\").replace(/"/g, '\\"')}"`;
const basePath = (id) => `${appHome()}/data/schedules/${id}`;
const unitName = (id) => `herdr-schedule-${id}`;
const launchLabel = (id) => `dev.herdr.schedule.${id}`;
const MODEL_AGENTS = new Set(["pi", "claude", "codex"]);

function clock(value) {
  const match = String(value).match(/^(\d\d):(\d\d)$/);
  if (!match) return null;
  const hour = Number(match[1]);
  const minute = Number(match[2]);
  return hour < 24 && minute < 60 ? { hour, minute } : null;
}

function scheduleText(schedule) {
  if (schedule.cadence === "minutes") return `Every ${schedule.intervalMinutes} minute${schedule.intervalMinutes === 1 ? "" : "s"}`;
  if (schedule.cadence === "hourly") return "Every hour";
  if (schedule.cadence === "daily") return `Daily at ${schedule.time}`;
  if (schedule.cadence === "weekdays") return `Weekdays at ${schedule.time}`;
  return `Mondays at ${schedule.time}`;
}

function nextRun(schedule) {
  const now = new Date();
  if (schedule.cadence === "minutes") return new Date(now.getTime() + schedule.intervalMinutes * 60000);
  if (schedule.cadence === "hourly") {
    const next = new Date(now);
    next.setMinutes(0, 0, 0);
    next.setHours(next.getHours() + 1);
    return next;
  }
  const at = clock(schedule.time);
  if (!at) return null;
  const next = new Date(now);
  next.setHours(at.hour, at.minute, 0, 0);
  if (schedule.cadence === "daily") {
    if (next <= now) next.setDate(next.getDate() + 1);
  } else if (schedule.cadence === "weekdays") {
    if (next <= now) next.setDate(next.getDate() + 1);
    while (next.getDay() === 0 || next.getDay() === 6) next.setDate(next.getDate() + 1);
  } else {
    const days = (8 - next.getDay()) % 7;
    next.setDate(next.getDate() + days);
    if (next <= now) next.setDate(next.getDate() + 7);
  }
  return next;
}

function runnerScript(schedule, hcPath) {
  const runId = `schedule-${schedule.id}`;
  const start = [
    hcPath,
    "run",
    "--bg",
    "--json",
    "--no-parent",
    "--cwd",
    schedule.folder,
    "--label",
    `herdr.space=${runId}`,
    "--label",
    `herdr.schedule=${schedule.id}`,
  ].map(shQuote).join(" ");
  const argv = [...schedule.argv];
  if (schedule.model && MODEL_AGENTS.has(schedule.agentKey)) argv.push("--model", schedule.model);
  const shellCommand = argv.map(shQuote).join(" ");
  const program = [schedule.shell, "-lic", shellCommand].map(shQuote).join(" ");
  const hcCommand = shQuote(hcPath);
  const task = shQuote(schedule.task);
  return `#!/bin/sh
address=""
stop_run() {
  if [ -n "$address" ]; then
    ${hcCommand} kill "$address" >/dev/null 2>&1 || true
  fi
}
trap 'stop_run; exit 143' HUP INT TERM
existing=$(${hcCommand} ls --json --label ${shQuote(`herdr.schedule=${schedule.id}`)})
existing_code=$?
[ "$existing_code" -eq 0 ] || exit "$existing_code"
case "$existing" in
  *'"terminals":[]'*) ;;
  *) printf '%s\\n' "A previous run is still live; skipping."; exit 0 ;;
esac
run_id="$(date -u +%Y%m%dT%H%M%SZ)-$$"
started=$(${start} --label "herdr.tab=${runId}-$run_id" --label "herdr.run=$run_id" -- ${program})
start_code=$?
printf '%s\\n' "$started"
[ "$start_code" -eq 0 ] || exit "$start_code"
address=$(printf '%s\\n' "$started" | sed -n 's/.*"address":"\\([^"]*\\)".*/\\1/p')
[ -n "$address" ] || exit 1
${hcCommand} send "$address" ${task} || { stop_run; exit 1; }
tries=0
while [ "$tries" -lt 120 ]; do
  current=$(${hcCommand} get "$address" --json) || break
  case "$current" in
    *'"state":"finished"'*) break ;;
    *'"status":'*'"state":"working"'*|*'"status":'*'"state":"blocked"'*|*'"status":'*'"state":"error"'*|*'"status":'*'"state":"idle"'*|*'"status":'*'"state":"done"'*) break ;;
  esac
  tries=$((tries + 1))
  sleep 0.5
done
while :; do
  waited=$(${hcCommand} wait --json --timeout 31536000 "$address")
  wait_code=$?
  printf '%s\\n' "$waited"
  case "$waited" in
    *'"status":"blocked"'*|*'"status":"error"'*)
      while :; do
        sleep 15
        current=$(${hcCommand} get "$address" --json) || exit "$wait_code"
        case "$current" in
          *'"state":"finished"'*) exit "$wait_code" ;;
          *'"status":'*'"state":"blocked"'*|*'"status":'*'"state":"error"'*) ;;
          *) break ;;
        esac
      done
      ;;
    *)
      ${hcCommand} kill "$address" >/dev/null 2>&1 || true
      exit "$wait_code"
      ;;
  esac
done
`;
}

function systemdCalendar(schedule) {
  if (schedule.cadence === "hourly") return "*-*-* *:00:00";
  const time = `${schedule.time}:00`;
  if (schedule.cadence === "daily") return `*-*-* ${time}`;
  if (schedule.cadence === "weekdays") return `Mon..Fri *-*-* ${time}`;
  return `Mon *-*-* ${time}`;
}

function systemdFiles(schedule, runner) {
  const name = unitName(schedule.id);
  const timing = schedule.cadence === "minutes"
    ? `OnActiveSec=${schedule.intervalMinutes}min\nOnUnitActiveSec=${schedule.intervalMinutes}min`
    : `OnCalendar=${systemdCalendar(schedule)}\nPersistent=true`;
  return {
    service: `[Unit]\nDescription=Herdr schedule: ${schedule.name}\n\n[Service]\nType=oneshot\nExecStart=${unitQuote(runner)}\nTimeoutStopSec=10\n`,
    timer: `[Unit]\nDescription=Herdr schedule: ${schedule.name}\n\n[Timer]\n${timing}\nAccuracySec=1min\nUnit=${name}.service\n\n[Install]\nWantedBy=timers.target\n`,
  };
}

function launchCalendar(schedule) {
  const at = clock(schedule.time) ?? { hour: 0, minute: 0 };
  const dict = (extra = "") => `<dict>${extra}<key>Hour</key><integer>${at.hour}</integer><key>Minute</key><integer>${at.minute}</integer></dict>`;
  if (schedule.cadence === "hourly") return "<dict><key>Minute</key><integer>0</integer></dict>";
  if (schedule.cadence === "daily") return dict();
  if (schedule.cadence === "weekly") return dict("<key>Weekday</key><integer>1</integer>");
  return `<array>${[1, 2, 3, 4, 5].map((day) => dict(`<key>Weekday</key><integer>${day}</integer>`)).join("")}</array>`;
}

function launchPlist(schedule, runner) {
  const base = basePath(schedule.id);
  return `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>${xml(launchLabel(schedule.id))}</string>
  <key>ProgramArguments</key><array><string>${xml(runner)}</string></array>
  ${schedule.cadence === "minutes" ? `<key>StartInterval</key><integer>${schedule.intervalMinutes * 60}</integer>` : `<key>StartCalendarInterval</key>${launchCalendar(schedule)}`}
  <key>ProcessType</key><string>Background</string>
  <key>StandardOutPath</key><string>${xml(`${base}/stdout.log`)}</string>
  <key>StandardErrorPath</key><string>${xml(`${base}/stderr.log`)}</string>
</dict>
</plist>
`;
}

function selfCheck() {
  const sample = { id: "test", name: "Test", folder: "/tmp/project", task: "Review changes", time: "09:15", cadence: "weekdays", argv: ["pi"], shell: "/bin/sh" };
  const runner = runnerScript(sample, "/tmp/hc");
  if (!runner.includes('--label "herdr.run=$run_id" --')) throw new Error("Schedule runner labels must precede the agent command.");
  if (!runner.includes("'/bin/sh' '-lic'")) throw new Error("Schedule runners must use a login shell.");
  if (systemdCalendar(sample) !== "Mon..Fri *-*-* 09:15:00") throw new Error("Invalid systemd weekday schedule.");
  if (!launchPlist(sample, "/tmp/run.sh").includes("<integer>5</integer>")) throw new Error("Invalid launchd weekday schedule.");
  const interval = { ...sample, cadence: "minutes", intervalMinutes: 15 };
  if (!systemdFiles(interval, "/tmp/run.sh").timer.includes("OnUnitActiveSec=15min")) throw new Error("Invalid systemd minute interval.");
  if (!launchPlist(interval, "/tmp/run.sh").includes("<integer>900</integer>")) throw new Error("Invalid launchd minute interval.");
}

async function put(path, content) {
  let previous = await readTextFile(path).catch(() => null);
  try {
    await writeTextFile(path, content, previous);
  } catch {
    previous = await readTextFile(path).catch(() => null);
    await writeTextFile(path, content, previous);
  }
}

async function command(name, args, message) {
  const result = await exec(name, args);
  if (result.code !== 0) throw new Error((result.stderr || result.stdout || message).trim());
  return result;
}

async function commandAllow(name, args, message, allowed) {
  const result = await exec(name, args);
  const output = (result.stderr || result.stdout || "").trim();
  if (result.code !== 0 && !allowed.test(output)) throw new Error(output || message);
  return result;
}

async function hcPath() {
  const result = await exec("sh", ["-lc", "command -v hc || command -v herdr-core"]);
  const path = result.stdout.trim().split("\n")[0];
  if (result.code !== 0 || !path) throw new Error("Could not find hc in your login shell.");
  return path;
}

async function loginShell() {
  const result = await exec("sh", ["-lc", "printf %s \"${SHELL:-/bin/sh}\""]);
  const path = result.stdout.trim();
  if (result.code !== 0 || !path.startsWith("/")) throw new Error("Could not find your login shell.");
  return path;
}

async function writeScheduleFiles(schedule) {
  schedule.shell = schedule.shell || await loginShell();
  const base = basePath(schedule.id);
  const runner = `${base}/run.sh`;
  await command("mkdir", ["-p", base], "Could not create the schedule folder.");
  const core = await hcPath();
  await put(runner, runnerScript(schedule, core));
  await command("chmod", ["700", runner], "Could not make the schedule runner executable.");
  if (window()?.platform === "linux") {
    const files = systemdFiles(schedule, runner);
    await put(`${base}/${unitName(schedule.id)}.service`, files.service);
    await put(`${base}/${unitName(schedule.id)}.timer`, files.timer);
  } else if (window()?.platform === "macos") {
    await put(`${base}/${launchLabel(schedule.id)}.plist`, launchPlist(schedule, runner));
  }
}

async function linuxEnable(schedule) {
  const base = basePath(schedule.id);
  const name = unitName(schedule.id);
  await exec("systemctl", ["--user", "link", `${base}/${name}.service`, `${base}/${name}.timer`]);
  await command("systemctl", ["--user", "daemon-reload"], "Could not reload systemd.");
  await command("systemctl", ["--user", "enable", `${name}.timer`], "Could not enable the timer.");
  await command("systemctl", ["--user", "restart", `${name}.timer`], "Could not start the timer.");
}

async function linuxDisable(schedule) {
  const name = unitName(schedule.id);
  const missing = /not loaded|not found|could not be found|does not exist/i;
  await commandAllow("systemctl", ["--user", "disable", "--now", `${name}.timer`], "Could not disable the timer.", missing);
  await commandAllow("systemctl", ["--user", "stop", `${name}.service`], "Could not stop the active run.", missing);
}

async function macDomain() {
  const uid = await command("id", ["-u"], "Could not determine your macOS user id.");
  return `gui/${uid.stdout.trim()}`;
}

async function macEnable(schedule) {
  const label = launchLabel(schedule.id);
  const source = `${basePath(schedule.id)}/${label}.plist`;
  const agents = `${home()}/Library/LaunchAgents`;
  const target = `${agents}/${label}.plist`;
  const domain = await macDomain();
  await command("mkdir", ["-p", agents], "Could not create ~/Library/LaunchAgents.");
  await commandAllow("launchctl", ["bootout", `${domain}/${label}`], "Could not unload the old launchd job.", /could not find|not found|no such process/i);
  await command("cp", [source, target], "Could not install the launchd job.");
  await command("launchctl", ["enable", `${domain}/${label}`], "Could not enable the launchd job.");
  await command("launchctl", ["bootstrap", domain, target], "Could not load the launchd job.");
}

async function macDisable(schedule) {
  const label = launchLabel(schedule.id);
  const domain = await macDomain();
  const target = `${home()}/Library/LaunchAgents/${label}.plist`;
  await commandAllow("launchctl", ["bootout", `${domain}/${label}`], "Could not unload the launchd job.", /could not find|not found|no such process/i);
  await command("rm", ["-f", target], "Could not remove the launchd job.");
}

async function install(schedule) {
  const platform = window()?.platform;
  if (platform !== "linux" && platform !== "macos") throw new Error("Schedules currently support Linux and macOS.");
  await writeScheduleFiles(schedule);
  if (platform === "linux") await linuxEnable(schedule);
  else await macEnable(schedule);
}

async function disable(schedule) {
  if (window()?.platform === "linux") await linuxDisable(schedule);
  else if (window()?.platform === "macos") await macDisable(schedule);
}

async function runNow(schedule) {
  if (window()?.platform === "linux") {
    await command("systemctl", ["--user", "start", "--no-block", `${unitName(schedule.id)}.service`], "Could not start the schedule.");
  } else if (window()?.platform === "macos") {
    const domain = await macDomain();
    await command("launchctl", ["kickstart", `${domain}/${launchLabel(schedule.id)}`], "Could not start the schedule.");
  }
}

function input(state, t) {
  return Input.new(state).h(34).px(10).rounded(8).border_1().border_color(t.input).bg(t.background).text_size(12.5).text_color(t.foreground);
}

export default class Schedules extends View {
  init(_props, cx) {
    selfCheck();
    try {
      this.schedules = JSON.parse(localStorage.getItem(STORE) ?? "[]");
      if (!Array.isArray(this.schedules)) this.schedules = [];
      this.schedules = this.schedules.filter((schedule) => /^[a-z0-9-]+$/.test(schedule?.id ?? ""));
    } catch {
      this.schedules = [];
    }
    this.agents = [];
    this.runs = {};
    this.editing = null;
    this.busy = null;
    this.error = null;
    this.makeForm();
    this.editing = null;
    cx.spawn(async (cx) => {
      try { this.agents = (await knownAgents()).filter((agent) => agent.installed); }
      catch { this.error = "Could not load installed agents."; }
      try {
        const legacy = this.schedules.filter((schedule) => !schedule.shell);
        if (legacy.length) {
          const shell = await loginShell();
          for (const schedule of legacy) {
            schedule.shell = shell;
            if (schedule.enabled) await install(schedule);
            else await writeScheduleFiles(schedule);
          }
          this.persist();
        }
      } catch (error) {
        this.error = `Could not migrate existing schedules: ${String(error?.message ?? error)}`;
      }
      await this.refreshRuns();
      cx.notify();
    });
    cx.timer.every(15000, (cx) => cx.spawn(async (cx) => {
      await this.refreshRuns();
      cx.notify();
    }));
  }

  makeForm(schedule = null) {
    this.editing = schedule?.id ?? "new";
    this.name = InputState.new({ value: schedule?.name ?? "", placeholder: "Daily code review" });
    this.folder = InputState.new({ value: schedule?.folder ?? "", placeholder: "/path/to/repository" });
    this.time = InputState.new({ value: schedule?.time ?? "09:00", placeholder: "09:00" });
    this.interval = InputState.new({ value: String(schedule?.intervalMinutes ?? 15), placeholder: "15" });
    this.model = InputState.new({ value: schedule?.model ?? "", placeholder: "Default model" });
    this.task = TextareaState.new({ value: schedule?.task ?? "", placeholder: "What should the agent do?", rows: 5 });
    this.task.set_auto_grow(4, 8);
    this.cadence = schedule?.cadence ?? "daily";
    this.agentKey = schedule?.agentKey ?? null;
    this.oldAgent = schedule ? { key: schedule.agentKey, name: schedule.agentName, run: schedule.argv } : null;
  }

  persist() {
    localStorage.setItem(STORE, JSON.stringify(this.schedules));
  }

  selectedAgent() {
    return this.agents.find((agent) => agent.key === this.agentKey) ?? (this.oldAgent?.key === this.agentKey ? this.oldAgent : null);
  }

  async refreshRuns() {
    if (this.refreshing) return;
    this.refreshing = true;
    try {
      for (const schedule of this.schedules) {
        const result = await hc(["ls", "--all", "--json", "--label", `herdr.schedule=${schedule.id}`]).catch(() => null);
        try { this.runs[schedule.id] = result?.code === 0 ? JSON.parse(result.stdout).terminals ?? [] : []; }
        catch { this.runs[schedule.id] = []; }
      }
    } finally {
      this.refreshing = false;
    }
  }

  save(cx) {
    const agent = this.selectedAgent();
    const name = this.name.value().trim();
    const folder = this.folder.value().trim();
    const task = this.task.value().trim();
    const time = this.time.value().trim();
    const intervalMinutes = Number(this.interval.value().trim());
    const model = MODEL_AGENTS.has(agent?.key) ? this.model.value().trim() : "";
    if (!name || !folder || !task || !agent) {
      this.error = "Name, folder, installed agent, and task are required.";
      cx.notify();
      return;
    }
    if (!["hourly", "minutes"].includes(this.cadence) && !clock(time)) {
      this.error = "Time must use 24-hour HH:MM format.";
      cx.notify();
      return;
    }
    if (this.cadence === "minutes" && (!Number.isInteger(intervalMinutes) || intervalMinutes < 1 || intervalMinutes > 1440)) {
      this.error = "Minute interval must be a whole number from 1 to 1440.";
      cx.notify();
      return;
    }
    const old = this.schedules.find((item) => item.id === this.editing);
    const schedule = {
      id: old?.id ?? safeId(),
      name,
      folder,
      task,
      time,
      cadence: this.cadence,
      intervalMinutes,
      agentKey: agent.key,
      agentName: agent.name,
      argv: agent.run,
      model,
      enabled: old?.enabled ?? true,
    };
    this.busy = "save";
    this.error = null;
    cx.notify();
    cx.spawn(async (cx) => {
      try {
        schedule.shell = await loginShell();
        if (schedule.enabled) await install(schedule);
        else await writeScheduleFiles(schedule);
        const index = this.schedules.findIndex((item) => item.id === schedule.id);
        if (index < 0) this.schedules.push(schedule);
        else this.schedules[index] = schedule;
        this.persist();
        this.editing = null;
        notify({ title: old ? "Schedule updated" : "Schedule created", body: scheduleText(schedule), level: "success" });
        await this.refreshRuns();
      } catch (error) {
        this.error = String(error?.message ?? error);
      }
      this.busy = null;
      cx.notify();
    });
  }

  toggle(schedule, cx) {
    this.busy = schedule.id;
    this.error = null;
    cx.notify();
    cx.spawn(async (cx) => {
      try {
        if (schedule.enabled) await disable(schedule);
        else await install(schedule);
        schedule.enabled = !schedule.enabled;
        this.persist();
      } catch (error) {
        this.error = String(error?.message ?? error);
      }
      this.busy = null;
      cx.notify();
    });
  }

  remove(schedule, cx) {
    if (this.deleting !== schedule.id) {
      this.deleting = schedule.id;
      cx.notify();
      return;
    }
    this.busy = schedule.id;
    this.error = null;
    cx.notify();
    cx.spawn(async (cx) => {
      try {
        await disable(schedule);
        if (window()?.platform === "linux") {
          await commandAllow("systemctl", ["--user", "unlink", `${unitName(schedule.id)}.timer`, `${unitName(schedule.id)}.service`], "Could not unlink the schedule units.", /not loaded|not found|not linked|could not be found|does not exist/i);
          await command("systemctl", ["--user", "daemon-reload"], "Could not reload systemd.");
        }
        await command("rm", ["-rf", basePath(schedule.id)], "Could not remove the schedule files.");
        this.schedules = this.schedules.filter((item) => item.id !== schedule.id);
        this.persist();
        this.deleting = null;
      } catch (error) {
        this.error = String(error?.message ?? error);
      }
      this.busy = null;
      cx.notify();
    });
  }

  start(schedule, cx) {
    this.busy = schedule.id;
    this.error = null;
    cx.notify();
    cx.spawn(async (cx) => {
      try {
        if (!schedule.enabled) throw new Error("Enable this schedule before running it.");
        await runNow(schedule);
        notify({ title: "Schedule started", body: schedule.name, level: "info" });
      } catch (error) {
        this.error = String(error?.message ?? error);
      }
      this.busy = null;
      cx.notify();
    });
  }

  button(id, label, action, primary = false, enabled = true) {
    const t = theme();
    return h_flex().id(id).h(28).px(10).items_center().rounded(7).border_1().border_color(primary ? t.solid : t.input)
      .bg(primary ? t.solid : t.raised).text_color(primary ? t.solid_foreground : t.foreground).text_size(11.5).font_medium()
      .when(enabled, (el) => el.cursor_pointer().hover((s) => s.opacity(0.86)).on_click(action))
      .when(!enabled, (el) => el.opacity(0.45)).child(label);
  }

  form(t) {
    const label = (text) => div().pt(12).pb(6).text_size(11).font_medium().text_color(t.dim).child(text);
    const selected = this.selectedAgent();
    return v_flex().flex_1().min_h(0).overflow_y_scrollbar().p(14).text_color(t.foreground)
      .child(h_flex().items_center().child(div().flex_1().text_size(14).font_semibold().child(this.editing === "new" ? "New schedule" : "Edit schedule"))
        .child(this.button("schedule-cancel", "Cancel", (_e, cx) => { this.editing = null; this.error = null; cx.notify(); }, false, !this.busy)))
      .child(label("Name"))
      .child(input(this.name, t))
      .child(label("Repository or folder"))
      .child(h_flex().gap(7).child(input(this.folder, t).flex_1()).child(this.button("schedule-folder", "Browse", (_e, cx) => {
        cx.spawn(async (cx) => {
          const folder = await pickFolder({ prompt: "Choose" });
          if (folder) this.folder.set_value(folder);
          cx.notify();
        });
      })))
      .child(label("Agent"))
      .child(v_flex().gap(5).children(this.agents.map((agent) => h_flex().id(`agent-${agent.key}`).h(30).px(9).items_center().rounded(7)
        .border_1().border_color(agent.key === this.agentKey ? t.accent : t.border).bg(agent.key === this.agentKey ? t.selected : t.background)
        .cursor_pointer().on_click((_e, cx) => { this.agentKey = agent.key; cx.notify(); }).child(agent.name))))
      .when(this.agents.length === 0, (el) => el.child(div().text_size(12).text_color(t.dim).child("No installed agents found.")))
      .when(Boolean(selected && !this.agents.some((agent) => agent.key === selected.key)), (el) => el.child(div().text_size(12).text_color(t.muted).child(`Keeping ${selected.name}`)))
      .when(MODEL_AGENTS.has(this.agentKey), (el) => el
        .child(label("Model (optional)"))
        .child(input(this.model, t))
        .child(div().pt(5).text_size(10.5).text_color(t.dim).child(this.agentKey === "pi" ? "Format: provider/model, with optional :thinking" : "Uses this agent's --model option.")))
      .child(label("Repeat"))
      .child(h_flex().gap(5).flex_wrap().children(CADENCES.map((cadence) => this.button(`cadence-${cadence.id}`, cadence.label, (_e, cx) => {
        this.cadence = cadence.id;
        cx.notify();
      }, this.cadence === cadence.id))))
      .when(this.cadence === "minutes", (el) => el.child(label("Every N minutes")).child(input(this.interval, t)))
      .when(!["hourly", "minutes"].includes(this.cadence), (el) => el.child(label("Time, local timezone")).child(input(this.time, t)))
      .child(label("Task"))
      .child(Textarea.new(this.task).h(110).p(10).rounded(8).border_1().border_color(t.input).bg(t.background).text_size(12.5).text_color(t.foreground))
      .when(Boolean(this.error), (el) => el.child(div().pt(10).text_size(12).text_color(t.blocked).child(this.error)))
      .child(h_flex().pt(14).justify_end().child(this.button("schedule-save", this.busy === "save" ? "Saving…" : "Save schedule", (_e, cx) => this.save(cx), true, !this.busy)));
  }

  card(schedule, t) {
    const runs = this.runs[schedule.id] ?? [];
    const latest = runs.at(-1);
    const active = latest?.state === "live";
    const status = active ? (latest.status ?? "running") : latest ? (latest.reason ?? "finished") : "never run";
    const next = schedule.enabled ? nextRun(schedule) : null;
    return v_flex().id(`schedule-${schedule.id}`).p(11).gap(8).rounded(10).border_1().border_color(t.border).bg(t.surface)
      .child(h_flex().gap(8).items_center()
        .child(div().size(8).rounded(4).bg(schedule.enabled ? t.working : t.dim))
        .child(div().flex_1().min_w(0).truncate().text_size(13).font_semibold().text_color(t.foreground).child(schedule.name))
        .child(div().text_size(10.5).text_color(active ? t.working : t.dim).child(status)))
      .child(div().text_size(11.5).text_color(t.muted).child(`${scheduleText(schedule)} · ${schedule.agentName}${schedule.model ? ` · ${schedule.model}` : ""}`))
      .child(div().truncate().text_size(11).text_color(t.dim).child(schedule.folder))
      .when(Boolean(next), (el) => el.child(div().text_size(11).text_color(t.dim).child(`Next ${next.toLocaleString([], { weekday: "short", hour: "2-digit", minute: "2-digit" })}`)))
      .child(h_flex().gap(5).flex_wrap()
        .child(this.button(`run-${schedule.id}`, "Run now", (_e, cx) => this.start(schedule, cx), true, !this.busy && schedule.enabled))
        .when(active, (el) => el.child(this.button(`open-${schedule.id}`, "Open", () => run("terminal.peek", { terminal: latest.address }), false, !this.busy)))
        .child(this.button(`edit-${schedule.id}`, "Edit", (_e, cx) => { this.makeForm(schedule); this.error = null; cx.notify(); }, false, !this.busy))
        .child(this.button(`toggle-${schedule.id}`, schedule.enabled ? "Disable" : "Enable", (_e, cx) => this.toggle(schedule, cx), false, !this.busy))
        .child(this.button(`delete-${schedule.id}`, this.deleting === schedule.id ? "Confirm delete" : "Delete", (_e, cx) => this.remove(schedule, cx), false, !this.busy)));
  }

  render(cx) {
    const t = theme();
    if (this.editing) return this.form(t);
    return v_flex().size_full().min_h(0).bg(t.chrome).text_color(t.foreground)
      .child(h_flex().h(44).px(14).items_center().border_b(1).border_color(t.border)
        .child(div().flex_1().text_size(14).font_semibold().child("Schedules"))
        .child(this.button("schedule-add", "+ Add", (_e, cx) => {
          this.makeForm();
          this.agentKey = this.agents[0]?.key ?? null;
          this.error = null;
          cx.notify();
        }, true, !this.busy)))
      .when(Boolean(this.error), (el) => el.child(div().mx(12).mt(10).p(9).rounded(8).bg(t.blocked + "18").text_size(11.5).text_color(t.blocked).child(this.error)))
      .child(v_flex().id("schedule-list").flex_1().min_h(0).overflow_y_scrollbar().p(10).gap(8)
        .children(this.schedules.map((schedule) => this.card(schedule, t)))
        .when(this.schedules.length === 0, (el) => el.child(v_flex().flex_1().items_center().justify_center().px(24).gap(7)
          .child(div().text_size(13).font_medium().child("No schedules yet"))
          .child(div().text_size(11.5).text_color(t.dim).text_center().child("Recurring agents run through systemd on Linux and launchd on macOS, even when Herdr is closed.")))));
  }
}
