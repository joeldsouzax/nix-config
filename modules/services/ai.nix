{ config }:
{
  sops.secrets."claude_key" = {
    owner = "joel";
    group = "users";
    mode = "0400";
  };
}
