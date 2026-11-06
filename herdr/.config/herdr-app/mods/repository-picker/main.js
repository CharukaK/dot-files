import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { closeOverlay, exec, home, panes, props, run, spaces, theme } from "herdr";

export default class RepositoryPicker extends View {
  init(_props, cx) {
    this.repositories = [];
    this.filter = "";
    this.at = 0;
    this.error = "";
    this.loading = true;
    this.busy = false;
    this.handle = cx.focus_handle();
    this.input = InputState.new({ placeholder: "Filter repositories…" });
    this.input.on("change", (_e, cx) => {
      this.filter = this.input.value();
      this.at = 0;
      cx.notify();
    });
    this.input.on("submit", (_e, cx) => this.open(this.shown()[this.at], cx));
    this.input.focus();
    cx.timer.after(300, () => this.input.focus());
    cx.spawn(async cx => {
      const result = await exec(`${home()}/.config/herdr/bin/open-repository`, ["--list"]);
      if (result.code === 0) this.repositories = result.stdout.split("\n").map(s => s.trim()).filter(Boolean);
      else this.error = result.stderr.trim() || "Could not list repositories.";
      this.loading = false;
      cx.notify();
    });
  }

  shown() {
    const filter = this.filter.toLowerCase();
    return this.repositories.filter(path => !filter || path.toLowerCase().includes(filter));
  }

  close() {
    closeOverlay(props().overlay);
  }

  open(path, cx) {
    if (!path || this.busy) return;
    this.busy = true;
    this.error = "";
    cx.notify();
    cx.spawn(async cx => {
      const result = await exec(`${home()}/.config/herdr/bin/open-repository`, ["--ensure-main", path]);
      if (result.code !== 0) {
        this.error = result.stderr.trim() || "Could not create the main worktree.";
        this.busy = false;
        cx.notify();
        return;
      }
      const worktree = result.stdout.trim() || path;
      const openSpace = folder => {
        const paneList = panes();
        const existing = spaces().find(space => space.folder === folder || paneList.some(pane => pane.cwd === folder && space.tabs.some(tab => tab.id === pane.tab)));
        if (existing) run("space.select", { id: existing.id });
        else run("space.new", { folder });
      };
      openSpace(path);
      if (worktree !== path) openSpace(worktree);
      this.close();
    });
  }

  render() {
    const t = theme();
    const rows = this.shown();
    this.at = Math.min(this.at, Math.max(0, rows.length - 1));
    return v_flex()
      .id("repository-picker")
      .track_focus(this.handle)
      .size_full()
      .p(18)
      .gap(10)
      .bg(t.popover)
      .text_size(13)
      .on_key_down((e, cx) => {
        if (e.key === "escape") return this.close();
        if (!rows.length) return;
        if (e.key === "down") this.at = (this.at + 1) % rows.length;
        else if (e.key === "up") this.at = (this.at + rows.length - 1) % rows.length;
        else return;
        cx.stop_propagation();
        cx.notify();
      })
      .child(h_flex().items_center().child(div().flex_1().text_size(15).font_semibold().text_color(t.foreground).child("Open repository")).child(div().text_size(11).text_color(t.dim).child("Esc")))
      .child(h_flex().h(36).flex_none().px(10).gap(8).items_center().rounded(9).border_1().border_color(t.accent).bg(t.background)
        .child(svg("mods/workspace-chrome/search.svg").size(15).text_color(t.dim))
        .child(Input.new(this.input).flex_1().h_full().text_size(12.8).text_color(t.foreground)))
      .child(v_flex().h(420).min_h(0).overflow_y_scrollbar()
        .when(this.loading, el => el.child(div().p(10).text_color(t.dim).child("Looking for repositories…")))
        .when(Boolean(this.error), el => el.child(div().p(10).text_color(t.blocked).child(this.error)))
        .when(!this.loading && !this.error && rows.length === 0, el => el.child(div().p(10).text_color(t.dim).child("No matching repositories.")))
        .children(rows.map((path, index) => h_flex()
          .id(`repository-${index}`)
          .h(36)
          .flex_none()
          .px(10)
          .gap(9)
          .items_center()
          .rounded(7)
          .cursor_pointer()
          .when(index === this.at, el => el.bg(t.selected))
          .when(index !== this.at, el => el.hover(s => s.bg(t.hover)))
          .on_click((_e, cx) => this.open(path, cx))
          .child(svg("mods/workspace-chrome/folder.svg").size(14).text_color(t.dim))
          .child(div().truncate().text_color(t.foreground).child(path.replace(`${home()}/`, "~/"))))))
      .child(h_flex().justify_end().text_size(11).text_color(t.dim).child(this.busy ? "opening…" : "↑↓ choose · ↵ open · esc close"));
  }
}
