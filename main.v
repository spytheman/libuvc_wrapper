module main
import stbi
import uvc
import gg

const win_width    = 601
const win_height   = 601



fn main() {
	uvc.base(cb)
}

fn cb(frame &C.uvc_frame, user_ptr voidptr) {
	img_data := &u8(frame.data)
	println("STARTING CALLBACK")
	_ := stbi.load_from_memory(img_data, frame.data_bytes, stbi.LoadParams{3}) or {panic(err)}
	println("THE CALLBACK WORKED")
}

