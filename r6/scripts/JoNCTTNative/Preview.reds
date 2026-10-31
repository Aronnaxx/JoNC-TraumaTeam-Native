module JoNCTTNative

// Explicitly constructed by a future harness/UI adapter. No automatic HUD hook,
// game-world spawn, input binding, persistence or access to On Call systems.
public class JTTPreview extends IScriptable {
  public let patient: ref<JTTPatient>;
  public let card: ref<JTTPatientCard>;
  private let selectedTreatment: Int32;
  private let elapsed: Float;
  public let progressPercent: Int32;

  public static func Create(parent: ref<inkCompoundWidget>) -> ref<JTTPreview> {
    let preview = new JTTPreview();
    preview.patient = JTTPatient.Create("Araceli", "Cooley", "Gold", "got severals trojans on the cerebral modules that burn neurosensors.", new Vector4(-1474.382568, 2637.027832, 0.0, 1.0));
    preview.card = JTTPatientCard.Create(parent);
    preview.card.Refresh(preview.patient);
    return preview;
  }
  public func BeginTreatment(index: Int32) -> Bool {
    if !this.patient.BeginTreatment(index) { return false; }
    this.selectedTreatment = index;
    this.elapsed = 0.0;
    this.progressPercent = 0;
    return true;
  }
  public func Tick(delta: Float, roll: Int32) {
    if !this.patient.IsTreating() || delta <= 0.0 { return; }
    this.elapsed += delta;
    this.progressPercent = JTTContent.TreatmentPercent(this.selectedTreatment, this.elapsed);
    this.patient.TickTreatment(delta, roll);
    this.card.Refresh(this.patient);
  }
  public func Close() {
    this.patient.CancelTreatment();
    this.card.Dispose();
  }
}
