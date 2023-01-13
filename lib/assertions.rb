module Assertions
  def expect(condition, message)
    raise message unless condition
  end
end
