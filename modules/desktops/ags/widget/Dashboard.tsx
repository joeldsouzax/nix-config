// Monitoring dashboard — a top-right panel with clock, CPU/RAM/disk, and a
// services/health panel. All data comes from pure GLib (file reads + spawn),
// so there are no extra Astal-service import assumptions to get wrong.
//
// Extend it: the `SERVICES` list below drives the health panel — point it at
// your systemd units and HTTP endpoints. For richer widgets, import the Astal
// libs wired in ags.nix (e.g. `import Network from "gi://AstalNetwork"`).
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createPoll } from "ags/time"
import GLib from "gi://GLib"

// ── What to monitor ────────────────────────────────────────────────────────
// systemd user/system units and HTTP endpoints. Edit freely.
const SERVICES: Array<{ name: string; check: string }> = [
  { name: "nginx", check: "systemctl is-active nginx" },
  { name: "dnsmasq", check: "systemctl is-active dnsmasq" },
  // HTTP health example (exit 0 = up):
  { name: "trive.ai", check: "curl -sf -o /dev/null --max-time 2 https://trive.ai" },
]

// ── Helpers (pure GLib) ─────────────────────────────────────────────────────
function read(path: string): string {
  try {
    const [ok, bytes] = GLib.file_get_contents(path)
    return ok ? new TextDecoder().decode(bytes) : ""
  } catch {
    return ""
  }
}

// Wrap any producer so an exception degrades to a fallback instead of killing
// the widget — createPoll would otherwise propagate the throw and stop updating.
function safe<T>(fn: () => T, fallback: T): T {
  try {
    return fn()
  } catch {
    return fallback
  }
}

// True iff a spawn wait-status means "exited 0". Handles GLib API drift.
function exitOk(status: number): boolean {
  const f = (GLib as any).spawn_check_wait_status ?? (GLib as any).spawn_check_exit_status
  if (typeof f !== "function") return status === 0
  try {
    f(status) // returns true on 0, throws otherwise
    return true
  } catch {
    return false
  }
}

// Run a shell command; report exit success + trimmed stdout. Fully guarded so a
// missing binary or spawn failure can never throw into a poll.
function sh(cmd: string): { ok: boolean; out: string } {
  return safe(() => {
    const [, stdout, , status] = GLib.spawn_command_line_sync(cmd)
    const out = stdout ? new TextDecoder().decode(stdout).trim() : ""
    return { ok: exitOk(status), out }
  }, { ok: false, out: "" })
}

// CPU% via /proc/stat delta (state kept across polls).
let prevIdle = 0
let prevTotal = 0
function cpuUsage(): number {
  return safe(() => {
    const line = read("/proc/stat").split("\n")[0]
    const p = line.trim().split(/\s+/).slice(1).map(Number)
    if (p.length < 4) return 0
    const idle = p[3] + (p[4] || 0)
    const total = p.reduce((a, b) => a + (isNaN(b) ? 0 : b), 0)
    const dIdle = idle - prevIdle
    const dTotal = total - prevTotal
    prevIdle = idle
    prevTotal = total
    return dTotal > 0 ? Math.max(0, Math.round((1 - dIdle / dTotal) * 100)) : 0
  }, 0)
}

function memUsage(): number {
  return safe(() => {
    const info = read("/proc/meminfo")
    const get = (k: string) => Number((info.match(new RegExp(`${k}:\\s+(\\d+)`)) || [])[1] || 0)
    const total = get("MemTotal")
    const avail = get("MemAvailable")
    return total > 0 ? Math.round((1 - avail / total) * 100) : 0
  }, 0)
}

function diskUsage(): number {
  return safe(() => {
    const m = sh("df --output=pcent /").out.match(/(\d+)%/)
    return m ? Number(m[1]) : 0
  }, 0)
}

// ── Widgets ─────────────────────────────────────────────────────────────────
function Stat(props: { label: string; poll: () => number }) {
  const value = createPoll(0, 2000, () => safe(props.poll, 0))
  return (
    <box class="stat" spacing={8}>
      <label class="stat-label" label={props.label} />
      <label class="stat-value" hexpand halign={Gtk.Align.END} label={value(v => `${v}%`)} />
    </box>
  )
}

// A service is "up" iff its check command exits 0 — works for both
// `systemctl is-active` (0 = active) and `curl -sf` (0 = HTTP success).
function Service(svc: { name: string; check: string }) {
  const up = createPoll(false, 5000, () => safe(() => sh(svc.check).ok, false))
  return (
    <box class="service" spacing={8}>
      <label class="dot" label={up(u => (u ? "●" : "○"))} css={up(u => (u ? "color:#a6e3a1;" : "color:#f38ba8;"))} />
      <label class="service-name" label={svc.name} />
    </box>
  )
}

export default function Dashboard(gdkmonitor: Gdk.Monitor) {
  const { TOP, RIGHT } = Astal.WindowAnchor
  const time = createPoll("", 1000, () =>
    safe(() => GLib.DateTime.new_now_local().format("%H:%M:%S  ·  %a %d %b")!, ""),
  )

  return (
    <window
      visible
      name="dashboard"
      namespace="dashboard"
      class="Dashboard"
      gdkmonitor={gdkmonitor}
      anchor={TOP | RIGHT}
      layer={Astal.Layer.OVERLAY}
      margin_top={12}
      margin_right={12}
    >
      <box orientation={Gtk.Orientation.VERTICAL} spacing={10}>
        <label class="clock" label={time} />

        <box class="card" orientation={Gtk.Orientation.VERTICAL} spacing={6}>
          <Stat label="CPU" poll={cpuUsage} />
          <Stat label="RAM" poll={memUsage} />
          <box class="stat" spacing={8}>
            <label class="stat-label" label="DISK" />
            <label
              class="stat-value"
              hexpand
              halign={Gtk.Align.END}
              label={createPoll(0, 10000, diskUsage)(v => `${v}%`)}
            />
          </box>
        </box>

        <box class="card" orientation={Gtk.Orientation.VERTICAL} spacing={6}>
          <label class="card-title" label="Services" halign={Gtk.Align.START} />
          {SERVICES.map(Service)}
        </box>
      </box>
    </window>
  )
}
