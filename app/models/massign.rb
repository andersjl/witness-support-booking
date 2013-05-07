module Massign
  def massign( attrs, whitelist)
    attrs_keys = attrs.keys
    whitelist.each do |attr|
      attr = attr.to_s
      next unless attrs_keys.include? attr
      send "#{ attr}=", attrs[ attr]
    end
  end
end

