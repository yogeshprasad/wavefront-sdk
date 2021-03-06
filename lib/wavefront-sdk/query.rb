require_relative 'core/api'

module Wavefront
  #
  # Query Wavefront metrics.
  #
  class Query < CoreApi
    def api_base
      'chart'
    end

    # GET /api/v2/chart/api
    # Perform a charting query against Wavefront servers that
    # returns the appropriate points in the specified time window
    # and granularity. Any options can be pased through in the
    # options hash. This means the SDK does not have to closely
    # track the API, but also means the burden of data validation is
    # down to the user.
    #
    # @param query [String] Wavefront query to run
    # @param granularity [String] the required granularity for the
    #   reported data
    # @param t_start [Time, Integer] The start of the query window.
    #   May be a Ruby Time object, or epoch milliseconds
    # @param t_end [Time, Integer] The end of the query window.
    #   May be a Ruby Time object, or epoch milliseconds.
    # @param options [Hash] any other options defined in the API
    # @raise [ArgumentError] if query is not a string
    # @return [Wavefront::Response]
    #
    def query(query, granularity = nil, t_start = nil, t_end = nil,
              options = {})

      raise ArgumentError unless query.is_a?(String)
      wf_granularity?(granularity)
      raise Wavefront::Exception::InvalidTimestamp if t_start.nil?

      options[:q] = query
      options[:g] = granularity
      options[:s] = parse_time(t_start, true)
      options[:e] = parse_time(t_end, true) if t_end

      options.delete_if { |k, v| v == false && k != :i }
      api.get('api', options)
    end

    # GET /api/v2/chart/raw
    # Perform a raw data query against Wavefront servers that
    # returns second granularity points grouped by tags
    #
    # @param metric [String]  metric to query ingested points for
    #   (cannot contain wildcards)
    # @param source [String] source to query ingested points for
    #   (cannot contain wildcards).
    # @param t_start [Time, Integer] start time of window: defaults
    #   to one hour before t_end
    # @param t_end [Time, Integer] end time of window: defaults
    #   to now
    #
    def raw(metric, source = nil, t_start = nil, t_end = nil)
      raise ArgumentError unless metric.is_a?(String)

      options = { metric: metric }

      if source
        wf_source_id?(source)
        options[:source] = source
      end

      options[:startTime] = parse_time(t_start, true) if t_start
      options[:endTime] = parse_time(t_end, true) if t_end

      api.get('raw', options)
    end

    # Fake a response which looks like we get from all the other
    # paths. The default response is a single array.
    #
    def response_shim(body, status)
      { response: JSON.parse(body),
        status:   { result:  status == 200 ? 'OK' : 'ERROR',
                    message: '',
                    code:    status } }.to_json
    end
  end
end
