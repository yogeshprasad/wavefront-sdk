require_relative 'core/api'

module Wavefront
  #
  # View and manage events. Events are identified by their millisecond
  # epoch timestamp.
  #
  class Event < CoreApi
    def update_keys
      %i[startTime endTime name annotations]
    end

    # GET /api/v2/event
    # List all the events for a customer within a time range.
    #
    # @param from [Time, Integer] start of time range. The API
    #   requires this time as epoch milliseconds, but we will also
    #   accept it as a Ruby Time object.
    # @param to [Time, Integer] end ot time range. Can be epoch
    #   millisecods or a Ruby time. If not supplied, defaults to the
    #   current time.
    # @param cursor [String] event from which to start listing
    # @param limit [Integer] the number of events to return
    # @return [Wavefront::Response]
    #
    def list(from = nil, to = Time.now, limit = 100, cursor = nil)
      raise ArgumentError unless from && to
      wf_event_id?(cursor) if cursor

      from = parse_time(from, true)
      to   = parse_time(to, true)

      wf_ms_ts?(from)
      wf_ms_ts?(to)

      body = { earliestStartTimeEpochMillis: from,
               latestStartTimeEpochMillis:   to,
               cursor:                       cursor,
               limit:                        limit }

      api.get('', body.cleanse)
    end

    # POST /api/v2/event
    # Create a specific event.
    #
    # We used to validate keys and provide helpers for time fields.
    # Now ensuring a valid hash is entirely left up to the user.
    # Refer to the Swagger docs for more information.
    #
    # @param body [Hash] description of event
    # @return [Wavefront::Response]
    #
    def create(body)
      raise ArgumentError unless body.is_a?(Hash)
      api.post('', body, 'application/json')
    end

    # DELETE /api/v2/event/id
    # Delete a specific event.
    #
    # @param id [String] ID of the alert
    # @return [Wavefront::Response]
    #
    def delete(id)
      wf_event_id?(id)
      api.delete(id)
    end

    # GET /api/v2/event/id
    # Get a specific event / Get a specific historical version of a
    # specific event.
    #
    # @param id [String] ID of the event
    # @param version [Integer] version of event
    # @return [Wavefront::Response]
    #
    def describe(id, version = nil)
      wf_event_id?(id)
      wf_version?(version) if version
      fragments = [id]
      fragments += ['history', version] if version
      api.get(fragments.uri_concat)
    end

    # PUT /api/v2/event/id
    # Update a specific event
    #
    # This method helps you update one or more properties of an event.
    #
    # @param id [String] a Wavefront Event ID
    # @param body [Hash] description of event.
    # @param modify [Bool] if this is true, then the existing event
    #   object will be fetched and merged with the user-supplied body.
    #   The resulting object will be passed to the API. If this is
    #   false, the body will be passed through unmodified.
    # @return [Wavefront::Response]
    #
    def update(id, body, modify = true)
      wf_event_id?(id)
      raise ArgumentError unless body.is_a?(Hash)

      return api.put(id, body, 'application/json') unless modify

      api.put(id, hash_for_update(describe(id), body), 'application/json')
    end

    # POST /api/v2/event/id/close
    # Close a specific event.
    #
    # @param id [String] the ID of the event
    #
    def close(id)
      wf_event_id?(id)
      api.post([id, 'close'].uri_concat)
    end

    # GET /api/v2/event/id/tag
    # Get all tags associated with a specific event
    #
    # @param id [String] ID of the event
    # @return [Wavefront::Response]
    #   response keys
    #
    def tags(id)
      wf_event_id?(id)
      api.get([id, 'tag'].uri_concat)
    end

    # POST /api/v2/event/id/tag
    # Set all tags associated with a specific event.
    #
    # @param id [String] ID of the event
    # @param tags [Array] list of tags to set.
    # @return [Wavefront::Response]
    #   response keys
    #
    def tag_set(id, tags)
      wf_event_id?(id)
      tags = Array(tags)
      tags.each { |t| wf_string?(t) }
      api.post([id, 'tag'].uri_concat, tags, 'application/json')
    end

    # DELETE /api/v2/event/id/tag/tagValue
    # Remove a tag from a specific event.
    #
    # @param id [String] ID of the event
    # @param tag [String] tag to delete
    # @return [Wavefront::Response]
    #
    def tag_delete(id, tag)
      wf_event_id?(id)
      wf_string?(tag)
      api.delete([id, 'tag', tag].uri_concat)
    end

    # PUT /api/v2/event/id/tag/tagValue
    # Add a tag to a specific event.
    #
    # @param id [String] ID of the event
    # @param tag [String] tag to set.
    # @return [Wavefront::Response]
    #
    def tag_add(id, tag)
      wf_event_id?(id)
      wf_string?(tag)
      api.put([id, 'tag', tag].uri_concat)
    end
  end
end
