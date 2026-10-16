diffDrive.setupRobot()
// tigez configuration
// radio channel, group
diffDrive.setupRadio(52, 179)
diffDrive.setupWifi("Robot_Garage", "code4life2006")
// wheel diameter 91.04 mm
diffDrive.setWheelCalibration(91.04 * Math.PI / 360)
// effective track width, cm (not measured with a ruler)
diffDrive.setTrackWidth(11.62)
// from the rotation calibration
diffDrive.setConfigValue(ConfigField.RotationalSlip, 0.9829)
// left wheel motor port, right wheel motor port
diffDrive.setMotorPorts(MotorPort.M1, MotorPort.M2)
// left wheel speed multiplier
diffDrive.setWheelMultiplier(MotorSide.Left, 1)
// left wheel speed multiplier
basic.forever(function () {
	
})
