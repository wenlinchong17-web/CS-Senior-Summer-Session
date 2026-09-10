# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "HALF_DUPLEX" -parent ${Page_0}
  ipgui::add_param $IPINST -name "CLK_FREQ" -parent ${Page_0}
  ipgui::add_param $IPINST -name "BAUD" -parent ${Page_0}
}

proc update_PARAM_VALUE.HALF_DUPLEX { PARAM_VALUE.HALF_DUPLEX } {
}

proc validate_PARAM_VALUE.HALF_DUPLEX { PARAM_VALUE.HALF_DUPLEX } {
	return true
}

proc update_PARAM_VALUE.CLK_FREQ { PARAM_VALUE.CLK_FREQ } {
}

proc validate_PARAM_VALUE.CLK_FREQ { PARAM_VALUE.CLK_FREQ } {
	return true
}

proc update_PARAM_VALUE.BAUD { PARAM_VALUE.BAUD } {
}

proc validate_PARAM_VALUE.BAUD { PARAM_VALUE.BAUD } {
	return true
}

proc update_MODELPARAM_VALUE.HALF_DUPLEX { MODELPARAM_VALUE.HALF_DUPLEX PARAM_VALUE.HALF_DUPLEX } {
	set_property value [get_property value ${PARAM_VALUE.HALF_DUPLEX}] ${MODELPARAM_VALUE.HALF_DUPLEX}
}

proc update_MODELPARAM_VALUE.CLK_FREQ { MODELPARAM_VALUE.CLK_FREQ PARAM_VALUE.CLK_FREQ } {
	set_property value [get_property value ${PARAM_VALUE.CLK_FREQ}] ${MODELPARAM_VALUE.CLK_FREQ}
}

proc update_MODELPARAM_VALUE.BAUD { MODELPARAM_VALUE.BAUD PARAM_VALUE.BAUD } {
	set_property value [get_property value ${PARAM_VALUE.BAUD}] ${MODELPARAM_VALUE.BAUD}
}
