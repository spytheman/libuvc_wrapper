module uvc

#include <libuvc/libuvc.h>
#flag -luvc

pub enum VsDescSubtype {
	undefined           = 0x00
	input_header        = 0x01
	output_header       = 0x02
	still_image_frame   = 0x03
	format_uncompressed = 0x04
	frame_uncompressed  = 0x05
	format_mjpeg        = 0x06
	frame_jpeg          = 0x07
	format_mpeg2ts      = 0x0a
	format_dv           = 0x0c
	colorformat         = 0x0d
	format_frame_based  = 0x10
	frame_frame_based   = 0x11
	format_stream_based = 0x12
}

pub enum FrameFormat {
	unknown      = 0 // or -any
	// Any supported format
	uncompressed
	compressed
	/** YUYV/YUV2/YUV422: YUV encoding with one luminance value per pixel and
   * one UV (chrominance) pair for every two pixels.
   */
	yuyv
	uyvy
	// 24-bit RGB
	rgb
	bgr
	// Motion-JPEG (or JPEG) encoded images
	mjpeg
	h264
	// Greyscale images
	gray8
	gray16
	// Raw colour mosaic images
	by8
	ba81
	sgrbg8
	sgbrg8
	srggb8
	sbggr8
	// YUV420: NV12
	nv12
	// YUV: P010
	p010
	// Number of formats understood
	count
}

pub enum ErrorT {
	success               = 0 // Success (no error)
	error_io              = -1 // Input/output error
	error_invalid_param   = -2 // Invalid parameter
	error_access          = -3 // Access denied
	error_no_device       = -4 // No such device
	error_not_found       = -5 // Entity not found
	error_busy            = -6 // Resource busy
	error_timeout         = -7 // Operation timed out
	error_overflow        = -8 // Overflow
	error_pipe            = -9 // Pipe error
	error_interrupted     = -10 // System call interrupted
	error_no_mem          = -11 // Insufficient memory
	error_not_supported   = -12 // Operation not supported
	error_invalid_device  = -50 // Device is not UVC-compliant
	error_invalid_mode    = -51 // Mode not supported
	error_callback_exists = -52 // Resource has a callback (can't use polling and async)
	error_other           = -99 // Undefined error
}

@[typedef]
struct C.uvc_stream_ctrl_t {}

@[typedef]
struct C.uvc_context_t {}

@[typedef]
struct C.uvc_device_handle_t {}

@[typedef]
struct C.uvc_device_t {}

struct C.uvc_streaming_interface {}

struct C.uvc_frame_desc {
	parent                    &C.uvc_format_desc
	prev                      &C.uvc_frame_desc
	next                      &C.uvc_frame_desc
	bDescriptorSubtype        VsDescSubtype
	bFrameIndex               u8
	bmCapabilities            u8
	wWidth                    u16
	wHeight                   u16
	dwMinBitRate              u32
	dwMaxBitRate              u32
	dwMaxVideoFrameBufferSize u32
	dwDefaultFrameInterval    u32
	dwMinFrameInterval        u32
	dwMaxFrameInterval        u32
	dwFrameIntervalStep       u32
	bFrameIntervalType        u32
	dwBytesPerLine            u32
	intervals                 &u32
}

struct C.uvc_still_frame_desc {}

struct C.uvc_format_desc {}

@[typedef]
pub struct C.uvc_frame_t {
pub mut:
	data              voidptr // pointer to data
	data_bytes        int     // nb of bytes
	width             u32
	height            u32
	frame_format      FrameFormat
	step              usize
	sequence          u32
	library_owns_data u8
	metadata          voidptr
	metadata_bytes    usize
}

@[typedef]
struct C.uvc_format_desc_t {
	parent               &C.uvc_streaming_interface
	prev                 &C.uvc_format_desc
	next                 &C.uvc_format_desc
	bDescriptorSubtype   VsDescSubtype
	bFormatIndex         u8
	bNumFrameDescriptors u8
	guidFormat           [16]u8
	fourccFormat         [4]u8
	bBitsPerPixel        u8
	bmFlags              u8
	bDefaultFrameIndex   u8
	bAspectRatioX        u8
	bAspectRatioY        u8
	bmInterlaceFlags     u8
	bCopyProtect         u8
	bVariableSize        u8
	frame_descs          &C.uvc_frame_desc
	still_frame_desc     &C.uvc_still_frame_desc
}

fn C.uvc_init(ctx &&C.uvc_context_t, usb_ctx &C.libusb_context) ErrorT

type FnFrameCallback = fn (frame &C.uvc_frame_t, user_ptr voidptr)

fn C.uvc_start_streaming(devh &C.uvc_device_handle_t, ctrl &C.uvc_stream_ctrl_t, cb FnFrameCallback, user_ptr voidptr, flags u8) ErrorT

fn C.uvc_exit(&C.uvc_context_t)

fn C.uvc_print_diag(&C.uvc_device_handle_t, &C.FILE)

fn C.uvc_perror(ErrorT, &u8)

fn C.uvc_find_device(&C.uvc_context_t, &&C.uvc_device_t, int, int, &u8) ErrorT

fn C.uvc_open(&C.uvc_device_t, &&C.uvc_device_handle_t) ErrorT

fn C.uvc_unref_device(&C.uvc_device_t)

fn C.uvc_print_diag(&C.uvc_device_handle_t, &C.FILE)

fn C.uvc_get_format_descs(&C.uvc_device_handle_t) &C.uvc_format_desc_t

fn C.uvc_get_stream_ctrl_format_size(&C.uvc_device_handle_t, &C.uvc_stream_ctrl_t, FrameFormat, int, int, int) ErrorT

fn C.uvc_print_stream_ctrl(&C.uvc_stream_ctrl_t, &C.FILE)

fn C.uvc_set_ae_mode(&C.uvc_device_handle_t, u8) ErrorT

fn C.uvc_stop_streaming(&C.uvc_device_handle_t)

fn C.uvc_mjpeg2rgb(&C.uvc_frame_t, &C.uvc_frame_t) ErrorT // in, out

fn C.uvc_allocate_frame(int) &C.uvc_frame_t

////////////////////////////////

pub struct StreamingHandles {
	ctx           &C.uvc_context_t       = unsafe { nil }
	device        &C.uvc_device_t        = unsafe { nil }
	device_handle &C.uvc_device_handle_t = unsafe { nil }
	app_context   voidptr = unsafe { nil }
}

pub fn (mut handles StreamingHandles) finish_streaming() {
	C.uvc_stop_streaming(handles.device_handle)
	C.uvc_unref_device(handles.device)
	C.uvc_exit(handles.ctx)
}

pub fn start_streaming(cb FnFrameCallback, context voidptr) StreamingHandles {
	ctx := &C.uvc_context_t(unsafe { nil })
	dev := &C.uvc_device_t(unsafe { nil })
	devh := &C.uvc_device_handle_t(unsafe { nil })
	ctrl := C.uvc_stream_ctrl_t{}
	mut res := C.uvc_init(&ctx, unsafe { nil })
	if int(res) < 0 {
		C.uvc_perror(res, c'uvc_init')
		exit(0)
	}
	println('UVC initialized')
	// Locates the first attached UVC device, stores in dev
	res = C.uvc_find_device(ctx, &dev, 0, 0, unsafe { nil }) // seem to init the device
	if int(res) < 0 {
		C.uvc_perror(res, c'uvc_find_device') // no devices found
	} else {
		println('Device found')
		res = C.uvc_open(dev, &devh) // seem to init the handle
		if int(res) < 0 {
			C.uvc_perror(res, c'uvc_open') // unable to open device
		} else {
			println('Device opened')
			// C.uvc_print_diag(devh, C.stderr) // all info abt the device
			format_desc := C.uvc_get_format_descs(devh)
			frame_desc := &(format_desc.frame_descs)
			mut frame_format := FrameFormat.unknown
			mut width := 640
			mut height := 480
			mut fps := 30
			match format_desc.bDescriptorSubtype {
				.format_mjpeg {
					frame_format = unsafe { FrameFormat(C.UVC_COLOR_FORMAT_MJPEG) }
				}
				.format_frame_based {
					frame_format = unsafe { FrameFormat(C.UVC_FRAME_FORMAT_H264) }
				}
				else {
					frame_format = unsafe { FrameFormat(C.UVC_FRAME_FORMAT_YUYV) }
				}
			}
			if frame_desc != 0 {
				width = frame_desc.wWidth
				height = frame_desc.wHeight
				fps = 10000000 / frame_desc.dwDefaultFrameInterval
			}
			println('First format: (${fix_a_bytestr(format_desc.fourccFormat)}) ${width}x${height} ${fps}fps')
			res = C.uvc_get_stream_ctrl_format_size(devh, &ctrl, frame_format, width,
				height, fps) // result stored in ctrl

			// C.uvc_print_stream_ctrl(&ctrl, C.stderr);

			if int(res) < 0 {
				C.uvc_perror(res, c'get_mode') // device doesn't provide a matching stream
			} else {
				// Start the video stream. The library will call user function cb:
				//   cb(frame, (void *) 12345)
				res = C.uvc_start_streaming(devh, &ctrl, cb, context, 0)

				if int(res) < 0 {
					C.uvc_perror(res, c'start_streaming') // unable to start stream
				} else {
					println('Streaming... ${res}')

					// enable auto exposure - see uvc_set_ae_mode documentation
					println('Enabling auto exposure ...')
					uvc_auto_exposure_mode_auto := u8(2)
					res = C.uvc_set_ae_mode(devh, uvc_auto_exposure_mode_auto)
					if res == .success {
						println(' ... enabled auto exposure')
					} else if res == .error_pipe {
						// this error indicates that the camera does not support the full AE mode;
						// try again, using aperture priority mode (fixed aperture, variable exposure time)
						println(' ... full AE not supported, trying aperture priority mode')
						uvc_auto_exposure_mode_aperture_priority := u8(8)
						res = C.uvc_set_ae_mode(devh, uvc_auto_exposure_mode_aperture_priority)
						if int(res) < 0 {
							C.uvc_perror(res, c' ... uvc_set_ae_mode failed to enable aperture priority mode')
						} else {
							println(' ... enabled aperture priority auto exposure mode')
						}
					} else {
						C.uvc_perror(res, c' ... uvc_set_ae_mode failed to enable auto exposure mode')
					}
				}
			}
		}
	}
	return StreamingHandles{
		ctx: ctx
		device: dev
		device_handle: devh
		app_context: context
	}
}

fn fix_a_bytestr(a [4]u8) string {
	return []u8{len: 4, init: a[index]}.bytestr()
}
