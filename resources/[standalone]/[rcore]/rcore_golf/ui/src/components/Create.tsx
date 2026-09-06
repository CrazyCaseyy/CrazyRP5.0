import { useState, useEffect } from "react"
import "./Create.css";
import { fetchNui } from "../utils/fetchNui";
import { useTranslations } from "../providers/TranslationProvider";
import { Range, getTrackBackground } from "react-range";
import React from "react";

interface CreateProps {
    isJoin: boolean;
    caddyRentalAvailable: boolean;
    clubRentalAvailable: boolean;
    wagerExists: boolean;
    wagerValue: number;
    caddyPrice: string;
    clubPrice: string;
    holesToPlay: number[];
    wagersEnabled: boolean;
    minigameWagersEnabled: boolean;
    locationName: string;
    hasRegular: boolean;
    hasMinigames: boolean;
    selectedMinigame: string|null|undefined;
}

export function Create(props: CreateProps) {
    const [hasWager, setHasWager] = useState(false);
    const [wagerValue, setWagerValue] = useState<number|string>("");
    const [hasCaddy, setHasCaddy] = useState(false);
    const [rentingClub, setRentingClub] = useState(false);
    const [name, setName] = useState<string>();
    const translations = useTranslations();
    const [holesToPlay, setHolesToPlay] = useState(props.holesToPlay);
    const [selectedMinigame, setSelectedMinigame] = useState<string|null|undefined>(props.selectedMinigame);

    useEffect(() => {
      setHolesToPlay(props.holesToPlay)
    }, [props.holesToPlay])

    useEffect(() => {
      setSelectedMinigame(props.selectedMinigame);
    }, [props.selectedMinigame])

    function onWagerValueChange(event: any) {
        const value = parseInt(event.target.value);
        if (!isNaN(value) && value >= 0) {
            setWagerValue(value);
        } else {
            setWagerValue("")
        }
    }

    function onCreateClick() {
        let realWagerValue = null;
        if (hasWager && wagerValue && typeof(wagerValue) === "number" && wagerValue > 0) {
            realWagerValue = wagerValue;
        }

        fetchNui("joinLobby", {
            locationName: props.locationName,
            name: name,
            hasCaddy: hasCaddy,
            wagerValue: realWagerValue,
            rentingClub: rentingClub,
            holesToPlay: holesToPlay,
            selectedMinigame: selectedMinigame,
        })
    }

    function hasWagerWrap() {
        if (props.isJoin) {
            return props.wagerExists
        } else {
            return hasWager
        }
    }

    function setHolesToPlayWrap(value: number[]) {
      if (!props.isJoin) {
        setHolesToPlay(value);
      }
    }

    function handleMinigameChange(event: any) {
      if (!props.isJoin) {
        setSelectedMinigame(event.target.value);
      }
    }

    return (
        <>
            <h1 className="join-title">{translations.joinLobby}</h1>
            <p className="join-description">{translations.joinDescription}</p>

            <div className="create-form">
                <div>
                  {props.caddyRentalAvailable && !props.hasMinigames &&
                      <div className="form-section">
                          <p className="form-title">{translations.hireGolfCart} ({props.caddyPrice})</p>
                          <DoubleCheckbox primaryName={translations.noGolfCart} secondaryName={translations.rentGolfCart} isSecondaryChecked={hasCaddy} setIsSecondaryChecked={setHasCaddy} isLocked={false} />
                      </div>
                  }

                    {props.clubRentalAvailable &&
                        <div className="form-section">
                            <p className="form-title">{translations.hireClub} ({props.clubPrice})</p>
                            <DoubleCheckbox primaryName={translations.noClub} secondaryName={translations.rentClub} isSecondaryChecked={rentingClub} setIsSecondaryChecked={setRentingClub} isLocked={false} />
                        </div>
                    }
                    {(props.hasMinigames ? props.minigameWagersEnabled : props.wagersEnabled) &&
                        <div className="form-section" style={{visibility: (props.hasMinigames && (selectedMinigame === "training" || !selectedMinigame)) ? "hidden" : undefined}}>
                            <p className="form-title">{translations.wager}</p>
                            <DoubleCheckbox primaryName={translations.noWager} secondaryName={translations.addWager} isSecondaryChecked={hasWagerWrap()} setIsSecondaryChecked={setHasWager} isLocked={props.isJoin} />
                            {props.wagerExists &&
                                <input placeholder={translations.wagerPlaceholder} value={translations.currency + props.wagerValue} type="text" className="form-input e-disabled" disabled={true}></input>
                            }

                            {!props.wagerExists && props.isJoin &&
                                <input placeholder={translations.noWagerSet} type="number" className="form-input e-disabled" disabled={true}></input>
                            }

                            {!props.wagerExists && !props.isJoin &&
                                <input placeholder={translations.wagerPlaceholder} value={wagerValue} type={"number"} onChange={onWagerValueChange} className={hasWager ? "form-input" : "form-input hidden"}></input>
                            }
                        </div>
                    }

                    {props.hasRegular &&
                      <div className="form-section">
                          <p className="form-title">{translations.holesToPlay}</p>
                          <TwoThumbs rtl={false} values={holesToPlay} setValues={setHolesToPlayWrap}></TwoThumbs>
                      </div>
                    }

                    {props.hasMinigames &&
                    <>
                      <h1 className="minigame-title">{translations.selectMinigame}</h1>

                      <form className="minigame-container">
                        <label className="minigame-radio">
                          <input type="radio" name="options" value="training" checked={selectedMinigame === "training"} onChange={handleMinigameChange} />
                          {translations.minigameTraining}
                        </label>
                        <p className="minigame-description">{translations.minigameTrainingDescription}</p>
                        <label className="minigame-radio">
                          <input type="radio" name="options" value="score" checked={selectedMinigame === "score"} onChange={handleMinigameChange} />
                          {translations.minigameTopScore}
                        </label>
                        <p className="minigame-description">{translations.minigameTopScoreDescription}</p>
                        <label className="minigame-radio">
                          <input type="radio" name="options" value="pressure" checked={selectedMinigame === "pressure"} onChange={handleMinigameChange} />
                          {translations.minigameTopPressure}
                        </label>
                        <p className="minigame-description">{translations.minigameTopPressureDescription}</p>
                      </form>
                    </>
                    }
                </div>


                <button className="create-button" onClick={onCreateClick}>{props.isJoin ? translations.join : translations.createButton}</button>
            </div>
        </>
    )
}

const STEP = 1;
const MIN = 1;
const MAX = 9;

const TwoThumbs: React.FC<{ rtl: boolean, values: number[], setValues: Function }> = ({ rtl, values, setValues }) => {
  return (
    <div
      style={{
        display: 'flex',
        justifyContent: 'center',
        flexWrap: 'wrap'
      }}
    >
      <Range
        values={values}
        step={STEP}
        min={MIN}
        max={MAX}
        rtl={rtl}
        onChange={(values) => {
          setValues(values);
        }}
        renderMark={({ props, index }) => (
            <div
              {...props}
              style={{
                ...props.style,
                height: '16px',
                width: '5px',
                backgroundColor: index * STEP < values[0] ? '#548BF4' : '#ccc'
              }}
            />
          )}
        renderTrack={({ props, children }) => (
          <div
            onMouseDown={props.onMouseDown}
            onTouchStart={props.onTouchStart}
            style={{
              ...props.style,
              height: '36px',
              display: 'flex',
              width: '100%'
            }}
          >
            <div
              ref={props.ref}
              style={{
                height: '5px',
                width: '100%',
                borderRadius: '4px',
                background: getTrackBackground({
                  values,
                  colors: ['#ccc', '#548BF4', '#ccc'],
                  min: MIN,
                  max: MAX,
                  rtl
                }),
                alignSelf: 'center'
              }}
            >
              {children}
            </div>
          </div>
        )}
        renderThumb={({ props, isDragged }) => (
          <div
            {...props}
            style={{
              ...props.style,
              height: '32px',
              width: '32px',
              borderRadius: '4px',
              backgroundColor: '#FFF',
              display: 'flex',
              justifyContent: 'center',
              alignItems: 'center',
              boxShadow: '0px 2px 6px #AAA'
            }}
          >
            <div
              style={{
                height: '16px',
                width: '5px',
                backgroundColor: isDragged ? '#548BF4' : '#CCC'
              }}
            />
          </div>
        )}
      />
      <output style={{ marginTop: '15px', paddingBottom: '10px' }} id="output">
        {values[0]} - {values[1]}
      </output>
    </div>
  );
};


interface DoubleCheckboxProps {
    primaryName: string;
    secondaryName: string;
    isSecondaryChecked: boolean;
    setIsSecondaryChecked: Function;
    isLocked: boolean;
}

function DoubleCheckbox(props: DoubleCheckboxProps) {
    return (
        <div className="double-checkbox">
            <div className="checkbox-pair" onClick={() => !props.isLocked && props.setIsSecondaryChecked(false)}>
                <input className="checkbox" type="checkbox" checked={!props.isSecondaryChecked}></input>
                <span className="checkbox-text">{props.primaryName}</span>
            </div>

            <div className="checkbox-pair" onClick={() => !props.isLocked && props.setIsSecondaryChecked(true)}>
                <input className="checkbox" type="checkbox" checked={props.isSecondaryChecked}></input>
                <span className="checkbox-text">{props.secondaryName}</span>
            </div>
        </div>
    )
}