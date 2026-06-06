-- Marketing Hub: customer segments, campaign audience tracking, broadcast logging

-- ============================================================
-- CUSTOMER SEGMENTS (saved customer filters for targeting)
-- ============================================================
CREATE TABLE customer_segments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    filters JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_segments_workspace ON customer_segments(workspace_id);

ALTER TABLE customer_segments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "workspace_access" ON customer_segments
    FOR ALL TO authenticated
    USING (workspace_id IN (SELECT get_user_workspace_ids()))
    WITH CHECK (workspace_id IN (SELECT get_user_workspace_ids()));

-- ============================================================
-- CAMPAIGN AUDIENCE (which customers are targeted by a campaign)
-- ============================================================
CREATE TABLE campaign_audience (
    campaign_id UUID NOT NULL REFERENCES marketing_campaigns(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    segment_id UUID REFERENCES customer_segments(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (campaign_id, customer_id)
);

ALTER TABLE campaign_audience ENABLE ROW LEVEL SECURITY;

CREATE POLICY "workspace_access" ON campaign_audience
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM marketing_campaigns mc
            WHERE mc.id = campaign_id
            AND mc.workspace_id IN (SELECT get_user_workspace_ids())
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM marketing_campaigns mc
            WHERE mc.id = campaign_id
            AND mc.workspace_id IN (SELECT get_user_workspace_ids())
        )
    );

-- ============================================================
-- BROADCAST LOG (record of sent WhatsApp/SMS/email messages)
-- ============================================================
CREATE TABLE broadcast_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    campaign_id UUID REFERENCES marketing_campaigns(id) ON DELETE SET NULL,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    channel TEXT NOT NULL CHECK (channel IN ('whatsapp', 'sms', 'email')),
    message TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
    sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_broadcast_workspace ON broadcast_log(workspace_id);
CREATE INDEX idx_broadcast_campaign ON broadcast_log(campaign_id);

ALTER TABLE broadcast_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "workspace_access" ON broadcast_log
    FOR ALL TO authenticated
    USING (workspace_id IN (SELECT get_user_workspace_ids()))
    WITH CHECK (workspace_id IN (SELECT get_user_workspace_ids()));
