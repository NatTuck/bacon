#ifndef BACON_IMAGE_CL
#define BACON_IMAGE_CL

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

#endif
