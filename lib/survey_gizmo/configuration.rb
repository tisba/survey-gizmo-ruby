module SurveyGizmo
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?

    Pester.configure do |c|
      c.logger = ::Logger.new(STDERR)

      error_classes = [SurveyGizmo::RateLimitExceededError]
      error_classes += [StandardError] if configuration.retry_everything
      c.environments[:surveygizmo] = {
        max_attempts: configuration.retries + 1,
        delay_interval: configuration.retry_interval,
        on_retry: Pester::Behaviors::Sleep::Constant,
        retry_error_classes: error_classes
      }
    end
    SurveyGizmo.setup
  end

  def self.reset!
    self.configuration = Configuration.new
  end

  class Configuration
    DEFAULT_RESULTS_PER_PAGE = 50
    DEFAULT_API_VERSION = 'v4'

    attr_accessor :api_version
    attr_accessor :user
    attr_accessor :password
    attr_accessor :results_per_page
    attr_accessor :retries
    attr_accessor :retry_interval
    attr_accessor :retry_everything

    def initialize
      @results_per_page = DEFAULT_RESULTS_PER_PAGE
      @api_version = DEFAULT_API_VERSION
      @retries = 1
      @retry_interval = 60
      @retry_everything = false
    end
  end
end
