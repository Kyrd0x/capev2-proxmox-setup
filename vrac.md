Dans ```web/templates/submision/index.html```

avoir dans le ```<script>```
```js
$('.nav-tabs a').on('show.bs.tab', function (event) {
        const defaultMachine = $(event.target).data('default-machine');
        if (defaultMachine) {
            $('#form_machine').val(defaultMachine);
        }
    //...
});
```

Et dans le select du type de submit, avec ```data-default-machine``` le nom de la VM

```html
<ul class="nav nav-tabs">
    {% if resubmit %}
        <li class="nav-item active"><a class="nav-link" href="#resubmit" data-toggle="tab"><span class="fa fa-file"></span> File resubmission</a></li>
    {% else %}
        <li class="nav-item active"><a class="nav-link" href="#file" data-toggle="tab" data-default-machine="win10-malware"><span class="fa fa-file"></span> File(s)</a></li>
        {% if config.downloading_service %}
            <li class="nav-item"><a class="nav-link" href="#downloading_service" data-toggle="tab"><span class="fa fa-download"></span> Download</a></li>
        {% endif %}
        {% if config.url_analysis %}
            <li class="nav-item"><a class="nav-link" href="#url" data-toggle="tab" data-default-machine="win10-url"><span class="fa fa-globe"></span> URL</a></li>
        {% endif %}
        {% if config.dlnexec %}
            <li class="nav-item"><a class="nav-link" href="#dlurl" data-toggle="tab"><span class="fa fa-download"></span> DL&Exec</a></li>
        {% endif %}
        <li class="nav-item"><a class="nav-link" href="#pcap" data-toggle="tab"><span class="fa fa-network-wired"></span> PCAP</a></li>
        <li class="nav-item"><a class="nav-link" href="#static" data-toggle="tab"><span class="fa fa-tasks"></span> Static</a></li>
    {% endif %}
</ul>
```
