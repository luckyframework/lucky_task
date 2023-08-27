module LuckyTask::TextHelpers
  def arrow : String
    "▸"
  end

  def red_arrow : String
    arrow.colorize(:red)
  end

  def green_arrow : String
    arrow.colorize(:green)
  end
end
