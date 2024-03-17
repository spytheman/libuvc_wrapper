module main
import uvc
import gg

const win_width    = 601
const win_height   = 601



fn main() {
	uvc.base(cb)
}

fn cb(frame &C.uvc_frame, user_ptr voidptr) {
	println("STARTING CALLBACK")
	_ := uvc.mjpegframe_rgb(frame)
	println("THE CALLBACK WORKED")
}

