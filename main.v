module main

import uvc
import gg
import log

const wwidth = 640
const wheight = 480

struct App {
mut:
	gg           &gg.Context = unsafe { nil }
	istream_idx  int
	handles      uvc.StreamingHandles
	output_frame &C.uvc_frame_t = unsafe { nil }
	output_rgba8 &u32 = unsafe { nil }
}

fn (mut app App) init() {
	app.istream_idx = app.gg.new_streaming_image(wwidth, wheight, 4, pixel_format: .rgba8)
	app.output_rgba8 = unsafe { malloc(wwidth * wheight * 3) }
	app.output_frame = C.uvc_allocate_frame(wwidth * wheight * 4)
	app.output_frame.width = wwidth
	app.output_frame.height = wheight
	app.output_frame.frame_format = .rgb
	app.output_frame.library_owns_data = 0
	log.info('app.istream_idx: ${app.istream_idx}')
	log.info('app.handles: ${app.handles}')
	log.info('app.output_frame: ${app.output_frame}')
}

fn (mut app App) frame() {
	app.gg.begin()
	mut istream_image := app.gg.get_cached_image_by_idx(app.istream_idx)
	istream_image.update_pixel_data(unsafe { &u8(app.output_rgba8) })
	size := gg.window_size()
	app.gg.draw_image(0, 0, size.width, size.height, istream_image)
	app.gg.end()
}

fn cb(frame &C.uvc_frame_t, mut app App) {
	gc_disable()
	C.uvc_any2rgb(frame, app.output_frame)
	app.convert_output_frame_to_rgba8()
	gc_enable()
}

fn (mut app App) convert_output_frame_to_rgba8() {
	// vfmt off
	npixels := wwidth * wheight
	unsafe {		
	mut ps := &u8(app.output_frame.data)
	mut pt := &u8(app.output_rgba8)
	for _ in 0 .. npixels {
			*pt = *ps; pt++; ps++
			*pt = *ps; pt++; ps++
			*pt = *ps; pt++; ps++
			*pt = 255; pt++;
		}
	}
	// vfmt on
}

fn main() {
	mut app := &App{}
	app.gg = gg.new_context(
		window_title: 'Webcam Viewer'
		bg_color: gg.Color{5, 5, 5, 255}
		width: wwidth
		height: wheight
		init_fn: app.init
		frame_fn: app.frame
		user_data: app
	)
	app.handles = uvc.start_streaming(cb, app)
	defer {
		app.handles.finish_streaming()
	}
	app.gg.run()
}
