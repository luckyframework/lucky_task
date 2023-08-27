module LuckyTask::TextHelpers
  def arrow : String
    "▸"
  end

  def red_arrow : Colorize::Object(String)
    arrow.colorize(:red)
  end

  def green_arrow : Colorize::Object(String)
    arrow.colorize(:green)
  end
end
