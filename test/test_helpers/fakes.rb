class FakeDns
  def initialize(txt: {}, mx: {})
    @txt, @mx = txt, mx
  end

  def txt(name) = @txt.fetch(name, [])
  def mx(name) = @mx.fetch(name, [])
end
