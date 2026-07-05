// AGS v2 entry point — monitoring dashboard.
//
// STARTER config: iterate live on the desktop with `ags run ~/.config/ags`
// (hot-reloads on save). This was authored without a compile check, so if an
// import path differs on your AGS version, `ags run` will point to the line;
// `ags init` regenerates the canonical template to compare against.
import app from "ags/gtk4/app"
import style from "./style.scss"
import Dashboard from "./widget/Dashboard"

app.start({
  css: style,
  main() {
    // One dashboard window per monitor.
    app.get_monitors().map(Dashboard)
  },
})
