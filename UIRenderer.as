class UIRenderer {

    UIRenderer() {
        trace("UIRenderer creado");
    }

    void Render(MapStateManager@ &in msm) {
        if (!msm.hasMap || !msm.dataReady && !msm.finished) return;

        UI::Begin(" ", UI::WindowFlags::NoResize | UI::WindowFlags::NoTitleBar | UI::WindowFlags::AlwaysAutoResize);

        if (msm.response != ErrorTypes::OK && msm.response != ErrorTypes::RANKTARGET_LIMIT_EXCEEDED) {
            ErrorHandler(msm.response);   
        } else {
            string text = Icons::Terminal + " Rank " + msm.rankTarget + "/" + msm.totalPlayers + (msm.rankTarget == 1 ? " (WR)" : " (Top " + Text::Format("%.2f", Math::Floor((msm.rankTarget * 100.0f / float(msm.totalPlayers)) * 100.0f) / 100.0f) + "%)");
            UI::Text(text);
            
            if (msm.response == ErrorTypes::OK) {
                text = Icons::Search + " " + Text::Format("%.2f", msm.sm.leaderboardP) + "% Time: " + Time::Format(msm.targetScore);
                UI::Text(text);
                UI::SameLine();
                
                bool isBehind = msm.playerScore > msm.targetScore;
                vec4 color = msm.playerPos == 0 ? Color::LIGHT_GRAY : isBehind ? Color::DELTA_RED : Color::DELTA_BLUE;

                UI::PushStyleColor(UI::Col::Text, color);
                text = (msm.playerPos == 0 ? "No time" : Time::Format(Math::Abs(msm.playerScore - msm.targetScore)));
                msm.playerPos == 0 ? UI::Text(text) : UI::Text((isBehind ? "+" : "-") + text);

                UI::PopStyleColor();
            } else {
                ErrorHandler(msm.response);
            }
        }
        UI::End();
    }

    void ErrorHandler(ErrorTypes response) {
        UI::PushStyleColor(UI::Col::Text, Color::RED);
        switch (response) {
            case ErrorTypes::NO_RECORDS:
                UI::Text(Icons::Lock + "No records are available.");
                break;
            case ErrorTypes::PLAYER_COUNT_IS_NULL:
                UI::Text(Icons::Lock + "Map player count is unavailable.");
                break;
            case ErrorTypes::BAD_RESPONSE:
                UI::Text(Icons::Lock + "Bad response from Nadeo Services' API.");
                break;
            case ErrorTypes::FAILED_LEADERBOARDS:
                UI::PopStyleColor();
                UI::Text(Icons::ArrowRight + " Finish the map to see your target!");
                UI::PushStyleColor(UI::Col::Text, Color::RED);
                break;
            case ErrorTypes::RANKTARGET_LIMIT_EXCEEDED:
                UI::Text(Icons::Lock + "Delta Time is not available.");
                break;
            case ErrorTypes::NONEXISTENT_MAP:
                UI::Text(Icons::Lock + "Map is non existent.");
                break;
            default:
                UI::Text(Icons::Lock + "Unspecified error.");
                break;
        }
        UI::PopStyleColor();
    }
}