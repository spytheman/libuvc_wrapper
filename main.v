module main
import stbi
import os
import uvc

const win_width    = 601
const win_height   = 601

fn main() {
	uvc.base(cb)
}

fn cb(frame &C.uvc_frame, user_ptr voidptr) {
	println("NEW CB")
	base_array := os.read_bytes("0.jpg") or {panic(err)}
	img_data := &u8(base_array.data)
	img := stbi.load_from_memory(img_data, base_array.len, stbi.LoadParams{3}) or {panic(err)}
	println("THIS CALLBACK WORKED")
}

