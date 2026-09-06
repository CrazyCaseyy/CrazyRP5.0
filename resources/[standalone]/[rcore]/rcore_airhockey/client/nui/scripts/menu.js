var index = 0;
var totalItems = 0;
var displayIndex = 1;
var currentDescription = null;
var currentWarning = null;
var titleDescriptionColor = 'rgb(255, 255, 255)';
var AppInput = new Vue({
    el: '#input',
    data:
    {
        identifier: null,
        titleMenu: "rcore",
        float: "middle_screen",
        position: "middle_screen",
        ChooseText: "Accept",
        CloseText: "Close",
        message: "",
        visible: false,
        defaultTextInfront: '$',
    },

    methods: {
        Choose: function () {
            $.post('https:///inputmethod', JSON.stringify({
                identifier: this.identifier,
                message: this.message,
            }));
        },
        Close: function () {
            $.post(`https://${GetParentResourceName()}/close`, JSON.stringify({
                identifier: this.identifier,
            }));
        },
    },
});

var App = new Vue({
    el: '#menu',
    data:
    {
        identifier: null,
        titleMenu: "rcore",
        float: "left",
        position: "middle",
        visible: false,
        menu: [],
    },
    methods: {
        refresh() {
            this.$forceUpdate();  // Forces the Vue instance to re-render
        }
    }
});

var Notify = new Vue({
    el: '#notifyBar',
    data: {
        visible: false,
        mugshot: null,
        content: '',
    },
});

function GetDisplayIndex(currentIndex) {
    let count = 1;
    for (let index = 0; index < App.menu.length; index++) {
        var o = App.menu[index];
        var oIndex = o.number - 1;
        if (o.black || !o.visible) {
            continue;
        }
        if (oIndex == currentIndex) {
            break;
        }
        count++;
    }
    return count;
}


function GetNextAvailableIndex(currentIndex, direction) {
    var increment = direction === "down" ? 1 : -1;
    var newIndex = currentIndex;
    var maxIterations = App.menu.length; // Set a reasonable maximum number of iterations
    //  && App.menu[newIndex].type !== 6 
    for (var i = 0; i < maxIterations; i++) {
        newIndex = (newIndex + increment + App.menu.length) % App.menu.length;
        if (!App.menu[newIndex].black && App.menu[newIndex].enabled && App.menu[newIndex].visible) {
            return newIndex;
        }
    }
    // If no available index is found after the maximum iterations, return the current index
    return currentIndex;
}


function ScrollToIndex(idx) {
    const scrolldiv = document.getElementById('scrolldiv');
    const item = App.menu[idx];
    if (!scrolldiv || !item) return;

    const num = item.number;
    Vue.nextTick(() => {
        const el = scrolldiv.querySelector(`[data-number="${num}"]`);
        if (!el) return;
        el.scrollIntoView({ block: 'nearest', behavior: 'auto' });
    });
}

function GetLastVisibleIndex() {
    for (let i = App.menu.length - 1; i >= 0; i--) {
        const it = App.menu[i];
        if (it && it.visible && !it.black && it.type != 6) return i;
    }
    return -1;
}

function ScrollToIndexWithBlock(idx, block = 'nearest') {
    const scrolldiv = document.getElementById('scrolldiv');
    const item = App.menu[idx];
    if (!scrolldiv || !item) return;

    const num = item.number;
    Vue.nextTick(() => {
        const el = scrolldiv.querySelector(`[data-number="${num}"]`);
        if (!el) return;
        el.scrollIntoView({ block, behavior: 'auto' });
    });
}

function MoveDown() {
    const lastIndex = index;
    const next = GetNextAvailableIndex(index, "down");

    // No selectable item further down -> still scroll to show the bottom (disabled tail)
    if (next === lastIndex) {
        const lastVisible = GetLastVisibleIndex();
        if (lastVisible !== -1) ScrollToIndexWithBlock(lastVisible, 'end');
        return;
    }

    index = next;
    displayIndex = GetDisplayIndex(index);

    setActiveMenuIndex(index, true);
    currentDescription = App.menu[index].description;

    ScrollToIndexWithBlock(index, 'nearest');

    $.post(`https://${GetParentResourceName()}/selectNew`, JSON.stringify({
        index: App.menu[index].number,
        identifier: App.identifier,
        newIndex: App.menu[index].number,
        oldIndex: App.menu[lastIndex].number,
    }));
}

function setActiveMenuIndex(index_, active_) {
    for (var i = 0; i < App.menu.length; i++) { App.menu[i].active = false }
    if (App.menu[index_] != null) App.menu[index_].active = active_
    index = index_;
}

function getVolumeIndicatorProgress(volume) {
    // Clamp input to [0,1], coerce to number
    const v = Math.max(0, Math.min(1, Number(volume) || 0));
    // Scale to [0.1,0.9]
    return 0.1 + v * 0.8;
}

function parseBulletTag(str) {
    if (typeof str !== 'string') return { text: str, color: null };
    const re = /^\s*<bullet>(.*?)<\/bullet>\s*/i; // take first bullet tag at start
    const m = re.exec(str);
    if (!m) return { text: str, color: null };
    return { text: str.slice(m[0].length), color: (m[1] || '').trim() || null };
}

function applyBulletToItem(it) {
    // Only for type 2 items that render displayLabel on the right
    if (!it || it.type !== 2) return;
    const { text, color } = parseBulletTag(it.displayLabel);
    // these properties should exist from creation so Vue tracks them
    it.displayText = text;
    it.bulletColor = color;
}

// Menu
$(function () {

    function display(bool) {
        App.visible = bool;
    }
    display(false);
    window.addEventListener('message', function (event) {
        var item = event.data;
        if (item.type === "reset") {
            totalItems = 0
            App.menu = [];
        }

        if (item.type === "notifybar") {
            Notify.mugshot = item.mugData;
            Notify.content = item.content;
            Notify.visible = item.content !== null && item.content.length > 1;
        }

        if (item.type === "labelchangeindex") {

            var index_ = item.index - 1
            var currentItem = App.menu[index_];
            var items = currentItem.items;
            var newIndex = item.listIndex - 1

            currentItem.displayLabel = items[newIndex];
            currentItem.listIndex = newIndex;
            applyBulletToItem(currentItem);

            $.post(`https://${GetParentResourceName()}/updateLabel`, JSON.stringify({
                index: currentItem.number,
                listIndex: newIndex + 1,
                label: currentItem.label,
                displayLabel: items[newIndex],
                identifier: App.identifier,
            }));
        }

        if (item.type === "menuchangecurrentdescription") {
            currentDescription = item.description;
            App.refresh();
        }

        if (item.type === "itemchangedescription") {

            var index_ = item.index - 1
            var currentItem = App.menu[index_];
            currentItem.description = item.description
            currentDescription = App.menu[index].description;
            setActiveMenuIndex(index, true)

            $.post(`https://${GetParentResourceName()}/updateDescription`, JSON.stringify({
                index: App.menu[index].number,
                description: currentItem.description,
                identifier: App.identifier,
            }));
        }

        if (item.type === "itemchangeitems") {
            var index_ = item.index - 1
            var currentItem = App.menu[index_];
            currentItem.items = JSON.parse(item.data)
            currentItem.displayLabel = currentItem.items[0];
            currentItem.listIndex = 0;
            applyBulletToItem(currentItem);

            $.post(`https://${GetParentResourceName()}/updateItems`, JSON.stringify({
                index: App.menu[index].number,
                data: currentItem.items,
                identifier: App.identifier,
            }));
        }


        if (item.type === "itemchangelabel") {

            var index_ = item.index - 1
            var currentItem = App.menu[index_];

            if (item.secondLabel !== undefined && item.secondLabel !== null) {
                currentItem.secondLabel = item.secondLabel
                currentItem.displayLabel = item.secondLabel
                applyBulletToItem(currentItem);
            }


            if (item.label !== undefined && item.label !== null) {
                currentItem.label = item.label
            }

            $.post(`https://${GetParentResourceName()}/itemupdateLabel`, JSON.stringify({
                index: currentItem.number,
                listIndex: newIndex,
                label: currentItem.label,
                secondLabel: currentItem.secondLabel,
                identifier: App.identifier,
            }));
        }

        if (item.type === "addpack") {
            totalItems = 0
            currentDescription = null;
            App.menu = [];
            item.pack.forEach(pack => {
                const displayLabel = pack.data && pack.data.length > 0 ? pack.data[0] : "Unnamed";
                if (typeof pack.black === 'undefined' && pack.visible && pack.itemType != 6) {
                    totalItems++;
                }
                var o = {
                    type: pack.itemType,
                    label: pack.label,
                    enabled: pack.enabled,
                    visible: pack.visible,
                    description: pack.description,
                    checked: pack.checked,
                    number: pack.index,
                    secondLabel: pack.secondLabel,
                    mugShot: pack.mugShot,
                    r: pack.r,
                    g: pack.g,
                    b: pack.b,
                    progress: pack.progress,
                    scores: pack.scores,
                    active: false,
                    listIndex: 0,
                    displayLabel: displayLabel,
                    items: pack.data,
                    black: pack.black,
                    checked: pack.checked,
                    canChangeIndex: pack.canChangeIndex,
                    numHoles: pack.numHoles,
                    selectedHole: pack.selectedHole,
                    playerActive: pack.playerActive,
                    extralabelLeft: pack.extralabelLeft,
                    extralabelRight: pack.extralabelRight,
                    customCaptions: pack.customCaptions,
                    countable: pack.countable,
                    leftWidth: pack.leftWidth,
                    iconUrl: pack.iconUrl,
                }
                if (o.type == 2) {
                    o.listIndex = pack.listIndex - 1;
                    o.displayLabel = o.items[o.listIndex];
                    applyBulletToItem(o);
                } else if (o.type == 9) {
                    o.volumeProgress = getVolumeIndicatorProgress(o.progress);
                }

                App.menu.push(o);
            });
        }
        if (item.type === "title") {
            if (!App.menu || !App.menu.length) {
                totalItems = 0
                App.menu = [];
            }

            App.titleMenu = item.title
            App.caption = item.caption
            App.menuWidth = item.menuWidth
            App.customCounter = item.counter

            titleDescriptionColor = "rgb(" + item.color[0] + ", " + item.color[1] + ", " + item.color[2] + ")"
        }

        if (item.type === "toggleitemenabled") {
            var index_ = item.index - 1;
            if (App.menu[index_]) {
                App.menu[index_].enabled = item.enabled;
                if (index == index_ && !item.enabled) {
                    MoveDown()
                }
            }
        }

        if (item.type === "changeitemicon") {
            var index_ = item.index - 1;
            if (App.menu[index_]) {
                App.menu[index_].iconUrl = item.iconUrl;
            }
        }

        if (item.type === "toggleitemvisible") {
            var index_ = item.index - 1;
            if (App.menu[index_]) {
                App.menu[index_].visible = item.visible;
                if (index == index_ && !item.visible) {
                    MoveDown()
                }
            }
        }

        if (item.type === "scoreboardsetscore") {
            var index_ = item.index - 1;
            if (App.menu[index_]) {
                Vue.set(App.menu[index_].scores, item.holeIndex - 1, item.holeScore);
            }
        }

        if (item.type === "scoreboardchangeselectedhole") {
            var index_ = item.index - 1;
            if (App.menu[index_]) {
                App.menu[index_].selectedHole = item.selectedHole
            }
        }

        if (item.type === "scoreboardsetprogress") {
            var index_ = item.index - 1;

            if (App.menu[index_]) {


                //Vue.set(App.menu[index_].progress, item.progress); // Ensure reactivity

                App.menu[index_].progress = item.progress;

            }
        }

        if (item.type === "scoreboardtoggleactive") {
            var index_ = item.index - 1;
            if (App.menu[index_]) {


                //Vue.set(App.menu[index_].progress, item.progress); // Ensure reactivity

                App.menu[index_].playerActive = item.playerActive;

            }
        }

        if (item.type === "setwarningmessage") {
            currentWarning = item.message;
            setActiveMenuIndex(index, true)
            App.refresh();
        }

        if (item.type === "togglecheck") {
            var index_ = item.index - 1;
            if (App.menu[index_]) {
                App.menu[index_].checked = item.checked;
                $.post(`https://${GetParentResourceName()}/updatecheck`, JSON.stringify({
                    index: App.menu[index].number,
                    checked: item.checked,
                    identifier: App.identifier,
                }));
            }
        }

        if (item.type === "ui") {
            display(item.status);
            if (item.properties) {
                App.float = item.properties.float;
                App.position = item.properties.position;
            }
            currentWarning = item.warningMessage;
            App.identifier = item.identifier;
            index = GetNextAvailableIndex(-1, "down")
            displayIndex = GetDisplayIndex(index)
            currentDescription = index > -1 ? App.menu[index].description : null;
            setActiveMenuIndex(index, true)

            $.post(`https://${GetParentResourceName()}/open`, JSON.stringify({
                index: index > -1 ? App.menu[index].number : -1,
                identifier: App.identifier,
            }));
        }

        if (item.type === "togglevisibility") {
            App.visible = item.status;
        }

        if (App.visible && !AppInput.visible) {
            if (item.type === "enter") {
                if (App.menu && index >= 0 && index < App.menu.length) {
                    $.post(`https://${GetParentResourceName()}/clickItem`, JSON.stringify({
                        index: App.menu[index].number,
                        label: App.menu[index].label,
                        displayLabel: App.menu[index].displayLabel,
                        identifier: App.identifier,
                    }));
                }
            }

            if (item.type === "left") {
                if (index == -1) return;
                var currentItem = App.menu[index];
                var currentIndex = currentItem.listIndex;
                var items = currentItem.items;
                var newIndex = currentIndex === 0 ? items.length - 1 : currentIndex - 1;



                // handle volume
                if (currentItem.type === 9) {
                    if (currentItem.progress > 0) {
                        currentItem.progress = Math.max(0, currentItem.progress - 0.1);
                        currentItem.volumeProgress = getVolumeIndicatorProgress(currentItem.progress);
                        $.post(`https://${GetParentResourceName()}/updatevolume`, JSON.stringify({
                            index: currentItem.number,
                            progress: currentItem.progress,
                            identifier: App.identifier,
                        }));
                    }
                    return;
                }

                if (currentItem.canChangeIndex) {
                    currentItem.displayLabel = items[newIndex];
                    currentItem.listIndex = newIndex;
                    applyBulletToItem(currentItem);

                    $.post(`https://${GetParentResourceName()}/updateLabel`, JSON.stringify({
                        index: currentItem.number,
                        listIndex: newIndex + 1,
                        label: currentItem.label,
                        displayLabel: items[newIndex],
                        identifier: App.identifier,
                    }));
                }
                else {
                    $.post(`https://${GetParentResourceName()}/changeindexattempt`, JSON.stringify({
                        index: currentItem.number,
                        direction: -1,
                        identifier: App.identifier,
                    }));
                }
            }

            if (item.type === "right") {
                if (index == -1) return;
                var currentItem = App.menu[index];
                var currentIndex = currentItem.listIndex;
                var items = currentItem.items;
                var newIndex = currentIndex === items.length - 1 ? 0 : currentIndex + 1;


                // handle volume
                if (currentItem.type === 9) {
                    if (currentItem.progress < 1) {
                        currentItem.progress = Math.min(1, currentItem.progress + 0.1);
                        currentItem.volumeProgress = getVolumeIndicatorProgress(currentItem.progress);
                        $.post(`https://${GetParentResourceName()}/updatevolume`, JSON.stringify({
                            index: currentItem.number,
                            progress: currentItem.progress,
                            identifier: App.identifier,
                        }));
                    }
                    return;
                }


                if (currentItem.canChangeIndex) {
                    currentItem.displayLabel = items[newIndex];
                    currentItem.listIndex = newIndex;
                    applyBulletToItem(currentItem);

                    $.post(`https://${GetParentResourceName()}/updateLabel`, JSON.stringify({
                        index: currentItem.number,
                        listIndex: newIndex + 1,
                        label: currentItem.label,
                        displayLabel: items[newIndex],
                        identifier: App.identifier,
                    }));
                } else {
                    $.post(`https://${GetParentResourceName()}/changeindexattempt`, JSON.stringify({
                        index: currentItem.number,
                        direction: 1,
                        identifier: App.identifier,
                    }));
                }
            }

            if (item.type === "chooseitem") {
                var lastIndex = index;

                item.index = item.index - 1
                ScrollToIndex(item.index);
                setActiveMenuIndex(item.index, true)
                currentDescription = App.menu[index].description;
                displayIndex = GetDisplayIndex(index)

                $.post(`https://${GetParentResourceName()}/selectNew`, JSON.stringify({
                    index: App.menu[index].number,
                    identifier: App.identifier,
                    newIndex: App.menu[index].number,
                    oldIndex: App.menu[lastIndex].number,
                }));
            }

            if (item.type === "up") {
                if (index == -1) return;
                var lastIndex = index;
                index = GetNextAvailableIndex(index, "up")
                displayIndex = GetDisplayIndex(index)
                //document.getElementById('scrolldiv').scrollTop = index > 6 ? (38 * (index - 6)) : 0
                ScrollToIndex(index);
                setActiveMenuIndex(index, true)
                currentDescription = App.menu[index].description;
                $.post(`https://${GetParentResourceName()}/selectNew`, JSON.stringify({
                    index: App.menu[index].number,
                    identifier: App.identifier,
                    newIndex: App.menu[index].number,
                    oldIndex: App.menu[lastIndex].number,
                }));
            }

            if (item.type === "down") {
                if (index == -1) return;
                MoveDown();
            }
        }
    })
});
