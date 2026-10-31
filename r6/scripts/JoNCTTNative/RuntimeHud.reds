module JoNCTTNative

public class JTTRuntimeHud extends IScriptable {
  private let root: ref<inkCanvas>;
  private let status: ref<inkText>;
  private let subtitles: ref<inkText>;
  private let card: ref<JTTPatientCard>;
  private let progress: ref<inkRectangle>;
  public func Attach() {
    if IsDefined(this.root) { return; }
    let layer = GameInstance.GetInkSystem().GetLayer(n"inkHUDLayer");
    if !IsDefined(layer) || !IsDefined(layer.GetVirtualWindow()) { return; }
    this.root = new inkCanvas(); this.root.SetName(n"JTTNativeRuntime");
    this.root.SetSize(3840.0,2160.0); this.root.SetAnchor(inkEAnchor.Centered);
    this.root.SetAnchorPoint(Vector2(0.5,0.5)); this.root.SetInteractive(false);
    this.root.Reparent(layer.GetVirtualWindow());
    this.card = JTTPatientCard.Create(this.root);
    // Keep the copied card's own dimensions/typography; put its root at a stable HUD origin.
    this.card.widgets[0].SetAnchor(inkEAnchor.TopLeft);
    this.card.widgets[0].SetMargin(inkMargin(70.0,1100.0,0.0,0.0));
    this.status = this.Text(n"JTTNativeStatus",60.0,220.0,1800.0,180.0,34);
    this.subtitles = this.Text(n"JTTNativeSubtitle",800.0,1790.0,2240.0,250.0,36);
    this.progress = new inkRectangle(); this.progress.SetName(n"JTTNativeTreatmentProgress");
    this.progress.SetMargin(inkMargin(1350.0,1520.0,0.0,0.0));
    this.progress.SetTintColor(HDRColor(0.87,0.36,0.34,1.0)); this.progress.Reparent(this.root);
  }
  private func Text(name: CName,x: Float,y: Float,w: Float,h: Float,size: Int32) -> ref<inkText> {
    let text = new inkText(); text.SetName(name);
    text.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily"); text.SetFontStyle(n"Medium");
    text.SetFontSize(size); text.SetTintColor(HDRColor(0.87,0.36,0.34,1.0));
    text.SetSize(w,h); text.SetMargin(inkMargin(x,y,0.0,0.0)); text.SetWrapping(true);
    text.Reparent(this.root); return text;
  }
  public func Update(runtime: ref<JTTRuntime>, menu: Bool) {
    if !IsDefined(this.root) { return; }
    this.root.SetVisible(!menu);
    this.status.SetText("TRAUMA TEAM // NATIVE RESCUE\n"+runtime.message+"\n[F7] Abort and return safely");
    this.subtitles.SetText(runtime.Subtitle());
    let show = IsDefined(runtime.patient) && runtime.state >= 6 && runtime.state <= 10;
    this.card.root.SetVisible(show);
    if show { this.card.Refresh(runtime.patient); }
    let treating = show && runtime.patient.IsTreating();
    this.progress.SetVisible(treating);
    if treating { this.progress.SetSize(900.0*runtime.patient.Progress(),16.0); }
  }
  public func Close() {
    if IsDefined(this.root) && IsDefined(this.root.GetParentWidget()) { (this.root.GetParentWidget() as inkCompoundWidget).RemoveChild(this.root); }
    this.root = null; this.card = null;
  }
}
