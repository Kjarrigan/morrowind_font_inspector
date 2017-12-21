# Code adapted from the https://github.com/OpenMW/openmw project just out of curiosity

FLOAT = 4
INT = 4
CHAR = 1

# typedef struct
# {
#     float x;
#     float y;
# } Point;
#
class Point < Struct.new :x, :y
  def self.byte_size
    2 * FLOAT
  end

  def ==(pt)
    self.x == pt.x && self.y == pt.y
  end
end

# typedef struct
# {
#     float u1; // appears unused, always 0
#     Point top_left;
#     Point top_right;
#     Point bottom_left;
#     Point bottom_right;
#     float width;
#     float height;
#     float u2; // appears unused, always 0
#     float kerning;
#     float ascent;
# } GlyphInfo;
class GlyphInfo < Struct.new :u1, :top_left, :top_right, :bottom_left, :bottom_right, :width, :height, :u2, :kerning, :ascent
  attr_accessor :binary
  def self.from_binary(binstring)
    u1, tl_x, tl_y, tr_x, tr_y, bl_x, bl_y, br_x, br_y, w, h, u2, k, a, should_be_empty = *binstring.unpack('gggggggggggggga*')

    glyph = new
    glyph.binary = binstring

    glyph.u1 = u1
    glyph.top_left = Point.new(tl_x, tl_y)
    glyph.top_right = Point.new(tr_x, tr_y)
    glyph.bottom_left = Point.new(bl_x, bl_y)
    glyph.bottom_right = Point.new(br_x, br_y)
    glyph.width = w
    glyph.height = h
    glyph.u2 = u2
    glyph.kerning = k
    glyph.ascent = a

    raise should_be_empty.inspect unless should_be_empty.empty?

    glyph
  end

  # there are quite a lot of Glyphs where just kerning is set to a value
  # don't know why but i assume they are the unused slots.
  ZERO_POINT = Point.new 0, 0
  def empty?
    bottom_left == ZERO_POINT && bottom_right == ZERO_POINT && top_left == ZERO_POINT && top_right == ZERO_POINT
  end

  def self.byte_size
    (6 * FLOAT) + (Point.byte_size * 4)
  end
end

Blob = Struct.new :columns, :rows, :to_blob
def load_font(fname, export_to_file=false)
  ############ Part 1 - Load the Font-Meta

  fnt = File.new(fname, 'rb')

  p font_size = fnt.read(FLOAT).unpack('f').first
  p _unkown = fnt.read(INT).unpack('l').first
  p _unkown = fnt.read(INT).unpack('l').first
  p font_name = fnt.read(CHAR*284).unpack('A*').first

  glyphs = []
  256.times do
    glyphs << GlyphInfo.from_binary(fnt.read(GlyphInfo.byte_size))
  end
  raise "FNT File invalid or not correctly parsed! There are remaining bytes!" unless fnt.eof?
  fnt.close

  ############ Part 2 - Load the Font-Texture

  tex = File.new(font_name+'.tex', 'rb')

  p width = tex.read(INT).unpack('l').first
  p height = tex.read(INT).unpack('l').first

  # 4 Channels RGBA
  blob = Blob.new width, height, bitmap_blob = tex.read(width*height*4)

  raise "FNT File invalid or not correctly parsed! There are remaining bytes!" unless tex.eof?

  tex.close

  # TODO:fix the coordinate calculation - this doesn't seem right
  #   require 'gosu'
  #
  #   tex = Gosu::Image.new(blob)
  #   tex.save(font_name+'.bmp')
  #
  #   glyphs.each_with_index do |glyph,idx|
  #     next if glyph.empty?
  #
  #     p x1 = glyph.top_left.x*width
  #     p y1 = glyph.top_left.y*height
  #     p w  = glyph.top_right.x*width - x1
  #     p h  = glyph.bottom_left.y*height - y1
  #
  #     glyph_blob = tex.subimage(x1.to_i, y1.to_i, w.to_i, h.to_i)
  #     glyph_blob.save("Glyp-#{idx}.bmp")
  #   end
end

load_font(ARGV[0]) if __FILE__ == $0
