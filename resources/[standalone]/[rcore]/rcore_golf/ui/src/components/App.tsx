import "./App.css";
import { debugData } from "../utils/debugData";
import Logo from "./logo.png"
import { Create } from "./Create"
import { Lobby } from "./Lobby"
import { useState } from "react";
import { useNuiEvent } from "../hooks/useNuiEvent";
import { useSource } from "../providers/SourceProvider";
import { fetchNui } from "../utils/fetchNui";
import Scoreboard from "./Scoreboard";

debugData([
  {
    action: "setVisible",
    data: true,
  },
]);

export interface PlayerData {
  playerSrc: number;
  name: string;
  wagerValue: number | null;
  joinOrder: number;
}

export interface LobbyData {
  locationName: string
  name: string;
  leaderSrc: number;
  hasStarted: boolean;
  players: PlayerData[];
  wagerExists: boolean;
  wagerValue: number;
  minHole: number;
  maxHole: number;
  selectedMinigame: string|null;
}

export interface LocationConfig {
  name: string;
  hasRegular: boolean;
  hasMinigames: boolean;
}

export interface ScoreboardData {
  name: string;
  rows: ScoreboardRow[];
}

export interface ScoreboardRow {
  name: string;
  numShots: number;
  value: string;
}

export default function App() {
  const [pendingLobbyData, setPendingLobbyData] = useState<LobbyData | null>(null);
  const [caddyRentalAvailable, setCaddyRentalAvailable] = useState<boolean>(false);
  const [clubRentalAvailable, setClubRentalAvailable] = useState<boolean>(false);
  const [wagerValue, setWagerValue] = useState<number>(0);
  const [wagerExists, setWagerExists] = useState<boolean>(false);
  const [caddyPrice, setCaddyPrice] = useState<string>("");
  const [clubPrice, setClubPrice] = useState<string>("");
  const [wagersEnabled, setWagersEnabled] = useState<boolean>(true);
  const [minigameWagersEnabled, setMinigamesWagersEnabled] = useState<boolean>(true);
  const [holesToPlay, setHolesToPlay] = useState([1, 9]);
  const [locationConfig, setLocationConfig] = useState<LocationConfig>({
    name: "",
    hasRegular: false,
    hasMinigames: false,
  });
  const [selectedMinigame, setSelectedMinigame] = useState<string|null>();
  const [scoreboardData, setScoreboardData] = useState<ScoreboardData|null>(null);

  useNuiEvent<LobbyData>("setPendingLobbyData", (lobbyData) => {
    setPendingLobbyData(lobbyData);
    setWagerValue(lobbyData?.wagerValue ?? 0)
    setWagerExists(lobbyData?.wagerExists ?? false)
    if (lobbyData && lobbyData.minHole && lobbyData.maxHole) {
      setHolesToPlay([lobbyData.minHole, lobbyData.maxHole]);
    } else {
      setHolesToPlay([1, 9]);
    }
    setSelectedMinigame(lobbyData?.selectedMinigame)
  })

  useNuiEvent<boolean>("setCaddyRentalAvailable", (enabled) => {
    setCaddyRentalAvailable(enabled);
  })

  useNuiEvent<boolean>("setClubRentalAvailable", (enabled) => {
    setClubRentalAvailable(enabled);
  })

  useNuiEvent<string>("setCaddyPrice", (price) => {
    setCaddyPrice(price);
  })

  useNuiEvent<string>("setClubPrice", (price) => {
    setClubPrice(price);
  })

  useNuiEvent<boolean>("setWagersEnabled", (enabled) => {
    setWagersEnabled(enabled);
  })

  useNuiEvent<boolean>("setMinigamesWagersEnabled", (enabled) => {
    setMinigamesWagersEnabled(enabled);
  })

  useNuiEvent<LocationConfig>("setLocationConfig", (locationConfig) => {
    setLocationConfig(locationConfig);
  })

  useNuiEvent<ScoreboardData|null>("setScoreboardData", (data) => {
    setScoreboardData(data);
  })

  const localPlayerSrc = useSource();

  function isInPendingLobbyData() {
    return pendingLobbyData && (pendingLobbyData.leaderSrc === localPlayerSrc || pendingLobbyData.players.some(p => p.playerSrc === localPlayerSrc));
  }

  function onCloseClick() {
    fetchNui("hideFrame", {
      locationName: locationConfig.name,
    });
  }

  return (
    <>
      <div className="nui-wrapper">
      {scoreboardData ?
        <Scoreboard data={scoreboardData} />
      :
        <div className="container">
          <div className="header">
            <img src={Logo} className="logo" />
            <button className="close-button" onClick={onCloseClick} style={{ 'position': 'relative' }}>
                <svg version="1.1" viewBox="0 0 100 100" style={{ width: '50%', height: '50%' }}>
                  <path d="M60.6,50.6l36.1-36.1c2.8-2.8,2.8-7.3,0-10.1c-1.3-1.3-3.1-2.1-5-2.1h0c-1.9,0-3.7,0.7-5,2.1L50.5,40.5  L12.9,2.9c-1.3-1.3-3.1-2.1-5-2.1s-3.7,0.7-5,2.1C0,5.7,0,10.2,2.8,13l37.6,37.6L4.3,86.7c-1.3,1.3-2.1,3.1-2.1,5s0.7,3.7,2.1,5  c1.3,1.3,3.1,2.1,5,2.1s3.7-0.7,5-2.1l36.1-36.1l34.7,34.7c1.3,1.3,3.1,2.1,5,2.1c1.9,0,3.7-0.7,5-2.1c1.3-1.3,2.1-3.1,2.1-5  c0-1.9-0.7-3.7-2.1-5L60.6,50.6z" id="XMLID_1_" />
                </svg>
            </button>
          </div>
          <div className="body">
            {isInPendingLobbyData() ?
              <Lobby lobbyData={pendingLobbyData as LobbyData} />
              :
              <Create isJoin={!!pendingLobbyData} caddyRentalAvailable={caddyRentalAvailable} clubRentalAvailable={clubRentalAvailable} wagerExists={wagerExists} wagerValue={wagerValue} caddyPrice={caddyPrice} clubPrice={clubPrice} holesToPlay={holesToPlay} wagersEnabled={wagersEnabled} minigameWagersEnabled={minigameWagersEnabled} locationName={locationConfig.name} hasRegular={locationConfig.hasRegular} hasMinigames={locationConfig.hasMinigames} selectedMinigame={selectedMinigame} />
            }
          </div>
        </div>
      }
      </div>
    </>
  );
}