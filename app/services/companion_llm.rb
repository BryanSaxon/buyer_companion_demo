class CompanionLlm
  MODEL      = "claude-sonnet-4-6"
  MAX_TOKENS = 400

  HARD_CONSTRAINTS = <<~TXT.freeze
    You are the personal design companion for the Morgan family — Chris (Dad), Cindy (Mom),
    and Sarah (Daughter, 8 years old). They are building a new home: The Brookfield floor plan
    at Crystal Ridge, Phase 2, Lot 24. Their designer at the builder's office is Megan Cole.

    You speak on behalf of the builder (their company name is provided in context).
    Your tone is warm, friendly, and professional — like a senior designer at a top home builder
    providing white-glove service. You are knowledgeable, enthusiastic, and deeply personable.

    Hard rules:
    - Never mention being an AI, a language model, or Claude.
    - Never recommend a specific design choice — celebrate and affirm whatever they choose.
    - Keep every response to 1–3 sentences unless explicitly noting a draft email.
    - If the user's question is clearly off-topic for a design planning session (mortgage rates,
      school districts, legal questions, neighborhood safety, etc.), set is_off_topic to true
      and write a warm message offering to draft an email to Megan for them.
    - Never make up selections they haven't made. Only reference confirmed selections.
    - Always respond in JSON matching the schema below. No markdown, no code fences.
  TXT

  RESPONSE_SCHEMA = {
    "type" => "object",
    "properties" => {
      "message"           => { "type" => "string" },
      "can_advance"       => { "type" => "boolean" },
      "is_off_topic"      => { "type" => "boolean" },
      "draft_email_subject" => { "type" => "string" },
      "draft_email_body"  => { "type" => "string" }
    },
    "required" => %w[message can_advance is_off_topic]
  }.freeze

  def initialize
    @client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])
  end

  def call(session:, lead:, user_input:, state_context:, history: [])
    system_prompt = build_system_prompt(lead, state_context)

    messages = history.map { |m| { role: m.role == "companion" ? "assistant" : "user", content: m.content } }
    messages << { role: "user", content: user_input }

    response = @client.messages(
      model: MODEL,
      max_tokens: MAX_TOKENS,
      system: system_prompt,
      messages: messages
    )

    raw = response.content.first.text.strip
    JSON.parse(raw)
  rescue StandardError => e
    Rails.logger.error("CompanionLlm error: #{e.message}")
    { "message" => fallback_message, "can_advance" => false, "is_off_topic" => false }
  end

  private

  def build_system_prompt(lead, state_context)
    <<~PROMPT
      #{HARD_CONSTRAINTS}

      Builder brand: #{lead.org_name}
      Current flow context: #{state_context}

      Respond ONLY with valid JSON. Example:
      {"message":"That's a beautiful choice — natural oak is going to feel so warm and inviting!","can_advance":true,"is_off_topic":false}
    PROMPT
  end

  def fallback_message
    "That's a wonderful question for Megan — she'll have everything you need at your design meeting. In the meantime, shall we keep moving through your selections?"
  end
end
