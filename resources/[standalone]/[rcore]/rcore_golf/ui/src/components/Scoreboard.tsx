import { ScoreboardData } from "./App";

interface ScoreboardProps {
    data: ScoreboardData
}

export default function Scoreboard(props: ScoreboardProps) {
    const data = props.data;

    return (
        <div className="flex w-1/3 bg-[#111111] opacity-90">
            <table className="table-auto w-full">
                <thead className="bg-[#FE9E00] text-black">
                    <th>Name</th>
                    <th>Position</th>
                    <th>Num Shots</th>
                    <th>{data.name}</th>
                </thead>
                <tbody>
                    {data.rows.map((row, index) => {
                        return (
                            <tr>
                                <td>{row.name}</td>
                                <td>{getOrdinalSuffix(index + 1)}</td>
                                <td>{row.numShots}</td>
                                <td>{row.value}</td>
                            </tr>
                        )
                    })}
                </tbody>
            </table>
        </div>
    )
}

const suffixes = ["th", "st", "nd", "rd"];

function getOrdinalSuffix(num: number) {
    const value = num % 100;
    if (value >= 11 && value <= 13) {
        return num + suffixes[0];
    }
    return num + (suffixes[value % 10] || suffixes[0]);
}