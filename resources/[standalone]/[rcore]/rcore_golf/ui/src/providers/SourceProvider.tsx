import React, {createContext, useContext, useState} from "react";
import { useNuiEvent } from "../hooks/useNuiEvent";

const SourceContext = createContext<number>(0);

export const SourceProvider: React.FC<{ children: React.ReactNode }> = ({children}) => {
    const [localPlayerSrc, setLocalPlayerSrc] = useState(0);

    useNuiEvent<number>("setLocalPlayerSrc", setLocalPlayerSrc);

    return (
        <SourceContext.Provider value={localPlayerSrc}>
            {children}
        </SourceContext.Provider>
    );
};

export const useSource = () => {
    return useContext(SourceContext);
}
