import React, {createContext, useContext, useState} from "react";
import { useNuiEvent } from "../hooks/useNuiEvent";


interface Translations {
    joinDescription: string;
    startLobby: string;
    disbandLobby: string;
    leaveLobby: string;
    joinLobby: string;
    createLobby: string;
    createButton: string;
    namePlaceholder: string;
    nameTitle: string;
    hireGolfCart: string;
    noGolfCart: string;
    rentGolfCart: string;
    hireClub: string;
    noClub: string;
    rentClub: string;
    wager: string;
    noWager: string;
    addWager: string;
    wagerPlaceholder: string;
    noWagerSet: string;
    join: string;
    golfLobby: string;
    player: string;
    currency: string;
    holesToPlay: string;
    selectMinigame: string;
    minigameTraining: string;
    minigameTopScore: string;
    minigameTopPressure: string;
    minigameTrainingDescription: string;
    minigameTopScoreDescription: string;
    minigameTopPressureDescription: string;
}

// Default structure to prevent TypeScript from complaining, this will be set to real values when the UI is opened.
// For development environment (aka in browser) these will be used.
function GetDefaultTranslations() {
    return {
        startLobby: "Start Lobby",
        disbandLobby: "Disband Lobby",
        leaveLobby: "Leave Lobby",
        joinLobby: "Join Lobby",
        createLobby: "Create Lobby",
        createButton: "Create",
        namePlaceholder: "Write your name...",
        joinDescription: "Register for a game with others, or play alone",
        nameTitle: "Name",
        hireGolfCart: "Hire golf cart",
        noGolfCart: "No golf cart",
        rentGolfCart: "Rent golf cart",
        hireClub: "Hire Golf Club",
        noClub: "No club",
        rentClub: "Rent club",
        wager: "Wager",
        noWager: "No wager",
        addWager: "Add wager",
        wagerPlaceholder: "Write wager...",
        noWagerSet: "No wager set",
        join: "Join",
        golfLobby: "Golf Lobby",
        player: "Player",
        currency: "",
        holesToPlay: "Holes To Play",
        selectMinigame: "Select Minigame",
        minigameTraining: "Training",
        minigameTrainingDescription: "Training Description",
        minigameTopScore: "Top Score",
        minigameTopScoreDescription: "Top Score Description",
        minigameTopPressure: "Top Pressure",
        minigameTopPressureDescription: "Top Pressure Description",
    }
}

const TranslationContext = createContext<Translations>(GetDefaultTranslations());

export const TranslationProvider: React.FC<{ children: React.ReactNode }> = ({children}) => {
    const [translations, setTranslations] = useState<Translations>(GetDefaultTranslations());

    useNuiEvent<Translations>("setTranslations", setTranslations);

    return (
        <TranslationContext.Provider value={translations}>
            {children}
        </TranslationContext.Provider>
    );
};

export const useTranslations = () => {
    return useContext(TranslationContext);
}
