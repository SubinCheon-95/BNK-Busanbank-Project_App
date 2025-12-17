enum UiKind { me, agent, system }

class UiMessage {
  final UiKind kind;
  final String text;

  UiMessage(this.kind, this.text);
}
