=begin
Arneis::AssetReceipt - Standardized record for every generated asset.
Provides full observability into model usage, timing, and costs.
=end

require 'json'

module Arneis
  class AssetReceipt
    attr_accessor :asset_id, :ts_started, :ts_ended, :model, :prompt, :status, :error_msg, :input_tokens, :output_tokens, :cost_usd

    def initialize(asset_id:, model:, prompt:)
      @asset_id = asset_id
      @model = model
      @prompt = prompt
      @ts_started = Time.now.iso8601
      @status = 'pending'
      @input_tokens = 0
      @output_tokens = 0
      @cost_usd = 0.0
    end

    def complete!(output_tokens: 0, input_tokens: 0, cost_usd: 0.0)
      @ts_ended = Time.now.iso8601
      @duration = (Time.parse(@ts_ended) - Time.parse(@ts_started)).round(2)
      @input_tokens = input_tokens
      @output_tokens = output_tokens
      @cost_usd = cost_usd
      @status = 'done'
    end

    def fail!(error_msg:)
      @ts_ended = Time.now.iso8601
      @duration = (Time.parse(@ts_ended) - Time.parse(@ts_started)).round(2)
      @error_msg = Config.sanitize(error_msg)
      @status = 'failed'
    end

    def save!(path)
      data = {
        asset_id: @asset_id,
        ts_started: @ts_started,
        ts_ended: @ts_ended,
        duration_sec: @duration,
        model: @model,
        prompt: @prompt,
        status: @status,
        error_msg: @error_msg,
        input_tokens: @input_tokens,
        output_tokens: @output_tokens,
        cost_usd: @cost_usd
      }
      # Redact entire JSON just to be safe
      File.write("#{path}.asset.json", Config.sanitize(data.to_json))
    end
  end
end
