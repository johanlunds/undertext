#
#  LanguageCell.rb
#  Undertext
#
#  Created by Johan Lundström on 2010-03-08.
#  Copyright (c) 2010 Johan Lundström.
#

# While constructing this I looked at some of Apple's examples:
# - AnimatedTableView's ATImageTextCell
# - DragNDropOutlineView's ImageAndTextCell
# - http://www.mail-archive.com/cocoa-dev@lists.apple.com/msg49975.html
# 
# Limitations:
# - no editing or selecting supported (also would need hitTestForEvent implemented)
# - no expansion tooltips (tooltips that are shown above the cell when the
#   the text in it is truncated).
# - Overrides almost no other methods. Examples: cellSize, imageRectForBounds, 
#   titleRectForBounds, setControlView, setBackgroundStyle, copyWithZone. This could
#   lead to problems
class LanguageCell < NSTextFieldCell
  
  PADDING = 2
  
  def setImage(value)
    # if we don't check this we get nil-errors. think it's because we don't
    # override/implement copyWithZone
    @imageCell = NSImageCell.alloc.init unless @imageCell
    @imageCell.setImage(value)
  end
  
  def drawInteriorWithFrame_inView(frame, controlView)
    if @imageCell.image
      imageFrame = NSRect.new
	  # last arg, 0 = NSMinXEdge. NSMinXEdge isn't available to 64-bit apps
      NSDivideRect(frame, imageFrame, frame, @imageCell.image.size.width + PADDING, 0)
      @imageCell.drawWithFrame_inView(imageFrame, controlView)
    end
    
    # frame argument here could have been modified by NSDivideRect above
    super_drawInteriorWithFrame_inView(frame, controlView)
  end
end
