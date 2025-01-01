/// This class has all the values for the state.
/// The main one is [counter], which replaces the old
/// state variable from the demo app.
class AppState {
  int initial = 0;
  int step = 1;
  int counter = 0;

  increment() {
    counter += step;
  }

  reset() {
    counter = initial;
  }
}