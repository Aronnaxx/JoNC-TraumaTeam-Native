module JoNCTTNative

// Port of the objective unlock graph only. World actions and trigger predicates
// must finish in an adapter before it calls Complete(). This is not a quest runner.
public class JTTObjectiveGraph extends IScriptable {
  private let active: array<Int32>;
  private let completed: array<Int32>;
  private let failed: Bool;

  public func Start() {
    ArrayClear(this.active);
    ArrayClear(this.completed);
    this.failed = false;
    ArrayPush(this.active, 0);
  }
  public func IsActive(index: Int32) -> Bool {
    return !this.failed && ArrayContains(this.active, index);
  }
  public func Complete(index: Int32) -> Bool {
    if !this.IsActive(index) { return false; }
    ArrayRemove(this.active, index);
    ArrayPush(this.completed, index);
    let next = JTTContent.NextObjectives(index);
    let i = 0;
    while i < ArraySize(next) {
      if !ArrayContains(this.completed, next[i]) && !ArrayContains(this.active, next[i]) {
        ArrayPush(this.active, next[i]);
      }
      i += 1;
    }
    return true;
  }
  public func Fail() { this.failed = true; ArrayClear(this.active); }
  public func IsComplete() -> Bool { return !this.failed && ArrayContains(this.completed, 11); }
}
