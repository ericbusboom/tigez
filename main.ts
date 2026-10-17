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

// ---------------- Line follower ----------------

// The line sensor has four eyes in a row under the front of the robot.
// Asking it over I2C gives one bit per eye: bit 0 is the left eye,
// bit 3 is the right eye. A 1 means that eye sees the black line.
function readSensors(): number {
    pins.i2cWriteNumber(0x1a, 4, NumberFormat.Int8LE)
    return pins.i2cReadNumber(0x1a, NumberFormat.UInt8LE, false) & 0b1111
}

// Where the line is, for each pattern the sensor can show.
// 0 means the line is under the middle of the robot. Positive means
// the line is to the LEFT, so the robot should turn left. Negative
// means it is to the right. The pictures are left to right, with a #
// where an eye sees the line.
const NO_LINE = 99
const LINE_POSITION = [
    NO_LINE,  // ....  no line
    3,        // #...  far left
    1,        // .#..  a little left
    2,        // ##..  left
    -1,       // ..#.  a little right
    NO_LINE,  // #.#.  makes no sense
    0,        // .##.  centred
    1,        // ###.  wide line, a little left
    -3,       // ...#  far right
    NO_LINE,  // #..#  makes no sense
    NO_LINE,  // .#.#  makes no sense
    NO_LINE,  // ##.#  makes no sense
    -2,       // ..##  right
    NO_LINE,  // #.##  makes no sense
    -1,       // .###  wide line, a little right
    0,        // ####  centred on a wide line
]

const SPEED = 15  // cm/s
const KP = 40     // how hard to turn: degrees per second of turning for each step the line is off centre
const KD = 0      // how much to resist sudden changes; leave at 0 until KP is working
const STOP_AFTER_CM = 230  // stop following after this much travel along the line (2.1 m)

let running = false

// ---------------- Distance travelled ----------------

// How far the robot has driven along its path, in cm. It adds up the
// small moves between calls, so it follows curves. poseX/poseY alone
// would only give the straight-line distance from the start.
let travelled = 0
let lastX = 0
let lastY = 0

// Start counting from where the robot is now.
function resetDistanceTravelled() {
    travelled = 0
    lastX = diffDrive.poseX()
    lastY = diffDrive.poseY()
}

// Call this once per tick. Returns the total so far.
function distanceTravelled(): number {
    const x = diffDrive.poseX()
    const y = diffDrive.poseY()
    travelled += Math.sqrt((x - lastX) * (x - lastX) + (y - lastY) * (y - lastY))
    lastX = x
    lastY = y
    return travelled
}

function followLine() {
    running = true
    let lastPosition = 0
    resetDistanceTravelled()
    diffDrive.driveTwist(SPEED, 0)
    while (diffDrive.driveTick() && running) {
        if (distanceTravelled() >= STOP_AFTER_CM) break
        let position = LINE_POSITION[readSensors()]
        // Lost the line? Keep turning the way we were already turning.
        if (position == NO_LINE) position = lastPosition
        const turn = KP * position + KD * (position - lastPosition)
        diffDrive.driveTwist(SPEED, turn)
        lastPosition = position
    }
    diffDrive.stop()
}

// A starts following the line, B stops.
input.onButtonPressed(Button.A, followLine)
input.onButtonPressed(Button.B, function () {
    running = false
})
