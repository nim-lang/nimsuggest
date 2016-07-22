# if nimsuggest can detect `symbol_from_config_nims`,
# then `undefined_A` should be detected by chk command.
when defined(symbolFromConfigNims):
  undefined_A
else:
  undefined_B
