module Remotipart
  module RenderOverrides
    # RADAR Temporary override until 
    # https://github.com/JangoSteve/remotipart/pull/126 is resolved
    def render_with_remotipart *args
      render_without_remotipart *args
      response_body
    end
  end
end