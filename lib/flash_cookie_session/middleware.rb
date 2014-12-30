module FlashCookieSession
  class Middleware
    USER_AGENT_MATCHER = /^(Adobe|Shockwave) Flash/.freeze
    HTTP_REFERER_MATCHER = /\.swf$/.freeze
    
    cattr_accessor :extra_ua_matcher

    def initialize(app, session_key = Rails.application.config.session_options[:key])
      @app = app
      @session_key = session_key
    end

    def call(env)
      referrer = env['HTTP_REFERER'].to_s.split('?').first

      if env['HTTP_USER_AGENT'] =~ self.extra_ua_matcher || env['HTTP_USER_AGENT'] =~ USER_AGENT_MATCHER || referrer =~ HTTP_REFERER_MATCHER
        req = Rack::Request.new(env)
        the_session_key = [ @session_key, req.params[@session_key] ].join('=').freeze if req.params[@session_key]

        if req.params['remember_token'] && req.params['remember_token'] != 'null'
          the_remember_token = [ 'remember_token', req.params['remember_token'] ].join('=').freeze
        else
          the_remember_token = nil
        end

        cookie_with_remember_token_and_session_key = [ the_remember_token, the_session_key ].compact.join('\;').freeze

        env['HTTP_COOKIE'] = cookie_with_remember_token_and_session_key if env['HTTP_COOKIE'].blank?
        env['HTTP_ACCEPT'] = "#{req.params['_http_accept']}".freeze if req.params['_http_accept']
      end

      @app.call(env)
    end
  end
end
