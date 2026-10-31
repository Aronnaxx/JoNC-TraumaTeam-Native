module JoNCTTNative

// Generated content. Native adapters do not execute raw CyberScript actions.
public class JTTContent extends IScriptable {
  public static func ObjectiveTitle(index: Int32) -> String {
    switch index {
      case 0: return "Go to MedCenter and meet the Officer";
      case 1: return "Join the squad.";
      case 2: return "Go inside the AV";
      case 3: return "Go to the area";
      case 4: return "Go to the victim";
      case 5: return "Protect the area";
      case 6: return "Apply first aids to the victim";
      case 7: return "Wait the order";
      case 8: return "Go back to the AV";
      case 9: return "Go back to MedCenter";
      case 10: return "Wait for the Sergeant";
      case 11: return "Finish the mission";
    }
    return "";
  }
  public static func TreatmentLabel(index: Int32) -> String {
    switch index {
      case 0: return "Apply first aid (Safe)";
      case 1: return "Reboot the firmware (Low Risk/Success)";
      case 2: return "Apply trauma hotfix to the secure boot (Medium Risk/Success)";
      case 3: return "Launch recovery and failsafe mode (High Risk/Success)";
    }
    return "";
  }
  public static func TreatmentMinimum(index: Int32) -> Int32 {
    switch index {
      case 0: return 5;
      case 1: return -2;
      case 2: return -5;
      case 3: return -10;
    }
    return 0;
  }
  public static func TreatmentMaximum(index: Int32) -> Int32 {
    switch index {
      case 0: return 10;
      case 1: return 15;
      case 2: return 20;
      case 3: return 30;
    }
    return 0;
  }
  public static func TreatmentDuration(index: Int32) -> Float {
    switch index {
      case 0: return 1.500000;
      case 1: return 4.500000;
      case 2: return 2.500000;
      case 3: return 2.500000;
    }
    return 0.0;
  }
  public static func TreatmentPercent(index: Int32, elapsed: Float) -> Int32 {
    switch index {
      case 0:
        return 0;
      case 1:
        if elapsed >= 4.000000 { return 100; }
        if elapsed >= 1.500000 { return 50; }
        return 0;
      case 2:
        if elapsed >= 2.000000 { return 100; }
        if elapsed >= 0.500000 { return 50; }
        return 0;
      case 3:
        if elapsed >= 2.000000 { return 100; }
        if elapsed >= 0.500000 { return 50; }
        return 0;
    }
    return 0;
  }
  public static func NextObjectives(index: Int32) -> array<Int32> {
    let result: array<Int32>;
    switch index {
      case 0:
        ArrayPush(result, 1);
        break;
      case 1:
        ArrayPush(result, 2);
        break;
      case 2:
        ArrayPush(result, 3);
        ArrayPush(result, 4);
        break;
      case 3:
        ArrayPush(result, 5);
        break;
      case 4:
        ArrayPush(result, 6);
        break;
      case 5:
        ArrayPush(result, 7);
        break;
      case 6:
        ArrayPush(result, 7);
        break;
      case 7:
        ArrayPush(result, 8);
        break;
      case 8:
        ArrayPush(result, 9);
        break;
      case 9:
        ArrayPush(result, 10);
        break;
      case 10:
        ArrayPush(result, 11);
        break;
      case 11:
        break;
    }
    return result;
  }
}
