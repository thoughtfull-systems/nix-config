self: super: {
  exwm-trampoline = self.concatTextFile {
    name = "exwm";
    files = [ ./exwm-trampoline ];
    executable = true;
    destination = "/bin/exwm-trampoline";
  };
}
