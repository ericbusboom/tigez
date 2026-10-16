// tigez configuration
diffDrive.setupRadio(52, 179)  // radio channel, group
diffDrive.setupWifi("Robot_Garage", "code4life2006")
diffDrive.setWheelCalibration(91.04 * Math.PI / 360)  // wheel diameter 91.04 mm
diffDrive.setTrackWidth(11.62)  // effective track width, cm (not measured with a ruler)
diffDrive.setConfigValue(ConfigField.RotationalSlip, 0.9829)  // from the rotation calibration
diffDrive.setMotorPorts(MotorPort.M1, MotorPort.M2)  // left wheel motor port, right wheel motor port
diffDrive.setWheelMultiplier(MotorSide.Left, 1)  // left wheel speed multiplier
diffDrive.setWheelMultiplier(MotorSide.Right, 1)  // right wheel speed multiplier

basic.forever(function () {
	
})
