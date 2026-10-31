module JoNCTTNative

// The legacy display says BPM, but its value is a treatment score, not physiology.
// Retained for parity. No health value is applied to a real NPC by this model.
public class JTTPatient extends IScriptable {
  public let firstName: String;
  public let familyName: String;
  public let membership: String;
  public let injury: String;
  public let health: Int32;
  public let location: Vector4;
  private let treating: Bool;
  private let treatment: Int32;
  private let elapsed: Float;

  public static func Create(firstName: String, familyName: String, membership: String, injury: String, location: Vector4) -> ref<JTTPatient> {
    let patient = new JTTPatient();
    patient.firstName = firstName;
    patient.familyName = familyName;
    patient.membership = membership;
    patient.injury = injury;
    patient.location = location;
    patient.health = 1;
    return patient;
  }

  public func BeginTreatment(index: Int32) -> Bool {
    if this.treating || this.health <= 0 || this.health > 50 || index < 0 || index > 3 { return false; }
    this.treatment = index;
    this.elapsed = 0.0;
    this.treating = true;
    return true;
  }

  // Caller advances only gameplay time; paused/menu frames must not advance this.
  // A supplied roll makes all treatment endpoints testable without RNG.
  public func TickTreatment(delta: Float, roll: Int32) -> Bool {
    if !this.treating || delta <= 0.0 { return false; }
    this.elapsed += delta;
    if this.elapsed < JTTContent.TreatmentDuration(this.treatment) { return false; }
    this.health += Clamp(roll, JTTContent.TreatmentMinimum(this.treatment), JTTContent.TreatmentMaximum(this.treatment));
    this.treating = false;
    return true;
  }

  public func CancelTreatment() { this.treating = false; this.elapsed = 0.0; }
  public func IsTreating() -> Bool { return this.treating; }
  public func CanEvacuate() -> Bool { return this.health > 50; }
  public func IsDead() -> Bool { return this.health <= 0; }
  public func Progress() -> Float {
    if !this.treating { return 0.0; }
    return ClampF(this.elapsed / JTTContent.TreatmentDuration(this.treatment), 0.0, 1.0);
  }
}
