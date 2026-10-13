public class checkTriggerRecursion {
  private static List<String> triggers = new List<String>();
  public static boolean canRun(String identifier) {
    if (triggers.indexOf(identifier) == -1) {
      triggers.add(identifier);
      return true;
    } else {
      return false;
    }
  }

  public static void reset() {
    triggers.clear();
  }
}