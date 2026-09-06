import { useSource } from "../providers/SourceProvider"
import { fetchNui } from "../utils/fetchNui"
import { LobbyData, PlayerData } from "./App"
import "./Lobby.css"
import DeleteIcon from "./delete.png"
import { useTranslations } from "../providers/TranslationProvider";

interface LobbyProps {
    lobbyData: LobbyData
}

export function Lobby(props: LobbyProps) {
    const translations = useTranslations();
    const localPlayerSrc = useSource();

    function isLobbyLeader() {
        return props.lobbyData.leaderSrc === localPlayerSrc;
    }

    function onDisbandClick() {
        fetchNui("disbandLobby", {
            locationName: props.lobbyData.locationName,
        });
    }

    function onLeaveClick() {
        fetchNui("leaveLobby", {
            locationName: props.lobbyData.locationName,
        });
    }

    function getWagerText() {
        return props.lobbyData.wagerExists && (translations.currency + props.lobbyData.wagerValue) || "N/A"
    }

    function onKickClick(playerData: PlayerData) {
        fetchNui("kickPlayer", {
            locationName: props.lobbyData.locationName,
            playerSrc: playerData.playerSrc,
        })
    }

    function onStartClick() {
        fetchNui("startGame", {
            locationName: props.lobbyData.locationName,
        })
    }

    return (
        <div className="lobby-container">
            <h1 className="lobby-title">{translations.golfLobby}</h1>
            <div className="table-container">
                <table className="lobby-table">
                    {props.lobbyData.players.map((playerData, index) => {
                        return (
                            <tr className="lobby-table-row">
                                <td className="lobby-table-data lobby-table-player">{translations.player} {index + 1}</td>
                                <td className="lobby-table-data lobby-table-name">{playerData.name}</td>
                                <td className="lobby-table-data lobby-table-wager">{translations.wager}: {getWagerText()}</td>
                                <td className="lobby-table-data lobby-table-icon">
                                    <img className="delete-icon" src={DeleteIcon} onClick={() => onKickClick(playerData)} />
                                </td>
                            </tr>
                        )
                    })}
                </table>
            </div>
            {isLobbyLeader() ?
                <div className="buttons-control">
                    <button className="disband-button" onClick={onDisbandClick}>{translations.disbandLobby}</button>
                    {!props.lobbyData.hasStarted &&
                        <button className="start-button" onClick={onStartClick}>{translations.startLobby}</button>
                    }
                </div>
                :
                <button className="disband-button" onClick={onLeaveClick}>{translations.leaveLobby}</button>
            }
        </div>
    )
}