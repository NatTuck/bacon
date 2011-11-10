#ifndef BACON_IMAGE_CL
#define BACON_IMAGE_CL

//
// Functions for Image2D objects
//
//

uchar
_bacon__image2d_read_uchar(read_only image2d_t image, uint yy, uint xx)
{
   const sampler_t SAMP = CLK_FILTER_NEAREST | CLK_NORMALIZED_COORDS_FALSE
       | CLK_ADDRESS_CLAMP_TO_EDGE;
   uint4 vec = read_imageui(image, SAMP, (int2)(xx, yy));
   return convert_uchar_sat(vec.x);
}

void
_bacon__image2d_write_uchar(write_only image2d_t image, uint yy, uint xx, uchar vv)
{
    uint4 vec;
    vec.x = vv;
    write_imageui(image, (int2)(xx, yy), vec);
}

ushort
_bacon__image2d_read_ushort(read_only image2d_t image, uint yy, uint xx)
{
   const sampler_t SAMP = CLK_FILTER_NEAREST | CLK_NORMALIZED_COORDS_FALSE
       | CLK_ADDRESS_CLAMP_TO_EDGE;
   uint4 vec = read_imageui(image, SAMP, (int2)(xx, yy));
   return convert_ushort_sat(vec.x);
}

void
_bacon__image2d_write_ushort(write_only image2d_t image, uint yy, uint xx, ushort vv)
{
    uint4 vec;
    vec.x = vv;
    write_imageui(image, (int2)(xx, yy), vec);
}

short
_bacon__image2d_read_short(read_only image2d_t image, uint yy, uint xx)
{
   const sampler_t SAMP = CLK_FILTER_NEAREST | CLK_NORMALIZED_COORDS_FALSE
       | CLK_ADDRESS_CLAMP_TO_EDGE;
   int4 vec = read_imagei(image, SAMP, (int2)(xx, yy));
   return convert_short_sat(vec.x);
}

void
_bacon__image2d_write_short(write_only image2d_t image, uint yy, uint xx, short vv)
{
    int4 vec;
    vec.x = vv;
    write_imagei(image, (int2)(xx, yy), vec);
}

ulong
_bacon__image2d_read_ulong(read_only image2d_t image, uint yy, uint xx)
{
   const sampler_t SAMP = CLK_FILTER_NEAREST | CLK_NORMALIZED_COORDS_FALSE
       | CLK_ADDRESS_CLAMP_TO_EDGE;
   uint4   vec1 = read_imageui(image, SAMP, (int2)(xx, yy));
   ushort4 vec2 = convert_ushort4_sat(vec1);
   return as_ulong(vec2);
}

void
_bacon__image2d_write_ulong(write_only image2d_t image, uint yy, uint xx, ulong vv)
{
   ushort4 vec1 = as_ushort4(vv);
   uint4   vec2 = convert_uint4_sat(vec1);
   write_imageui(image, (int2)(xx, yy), vec2);
}

//
// Functions for Image3D Objects
//
//

#ifndef BACON_ON_CPU
#pragma OPENCL EXTENSION cl_khr_3d_image_writes : enable

uchar
_bacon__image3d_read_uchar(read_only image3d_t image, uint zz, uint yy, uint xx)
{
   const sampler_t SAMP = CLK_FILTER_NEAREST | CLK_NORMALIZED_COORDS_FALSE
       | CLK_ADDRESS_CLAMP_TO_EDGE;
   uint4 vec = read_imageui(image, SAMP, (int4)(xx, yy, zz, 0));
   return convert_uchar_sat(vec.x);
}

void
_bacon__image3d_write_uchar(write_only image3d_t image, uint zz, uint yy, uint xx, uchar vv)
{
    uint4 vec;
    vec.x = vv;
    write_imageui(image, (int4)(xx, yy, zz, 0), vec);
}

ulong
_bacon__image3d_read_ulong(read_only image3d_t image, uint zz, uint yy, uint xx)
{
   const sampler_t SAMP = CLK_FILTER_NEAREST | CLK_NORMALIZED_COORDS_FALSE
       | CLK_ADDRESS_CLAMP_TO_EDGE;
   uint4   vec1 = read_imageui(image, SAMP, (int4)(xx, yy, zz, 0));
   ushort4 vec2 = convert_ushort4_sat(vec1);
   return as_ulong(vec2);
}

void
_bacon__image3d_write_ulong(write_only image3d_t image, uint zz, uint yy, uint xx, ulong vv)
{
   ushort4 vec1 = as_ushort4(vv);
   uint4   vec2 = convert_uint4_sat(vec1);
   write_imageui(image, (int4)(xx, yy, zz, 0), vec2);
}

#endif



#endif
