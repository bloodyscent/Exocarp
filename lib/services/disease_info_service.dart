class DiseaseInfo {
  final String name;
  final String description;
  final String causes;
  final String whyItMightAppear;
  final String contributingConditions;

  const DiseaseInfo({
    required this.name,
    required this.description,
    required this.causes,
    required this.whyItMightAppear,
    required this.contributingConditions,
  });
}

class DiseaseInfoService {
  static const Map<String, DiseaseInfo> _diseases = {
    'Anthracnose': DiseaseInfo(
      name: 'Anthracnose',
      description: 'Anthracnose is a fungal disease that can affect mango leaves and other parts of the mango plant. It commonly produces dark spots or lesions that may expand as the disease develops.',
      causes: 'It is caused by fungi in the Colletotrichum group. Disease development is often favored by warm, humid, and wet conditions.',
      whyItMightAppear: 'This leaf might show anthracnose symptoms because fungal infection can develop when moisture remains on the leaf for extended periods. The visible spots and lesions may become more noticeable as the infection progresses.',
      contributingConditions: 'High humidity, frequent rainfall, prolonged leaf wetness, poor air circulation, and infected plant material can contribute to disease development.',
    ),

    'Bacterial Canker': DiseaseInfo(
      name: 'Bacterial Canker',
      description: 'Bacterial canker is a bacterial disease that can affect mango plants and may produce dark or damaged areas on leaves and other plant parts.',
      causes: 'It is associated with bacterial infection, particularly bacteria that can enter plant tissues through natural openings or wounds.',
      whyItMightAppear: 'This leaf might have bacterial canker because bacterial infection can cause localized damage and discoloration. Environmental stress or physical damage may also make plant tissues more vulnerable.',
      contributingConditions: 'High humidity, rainfall, plant wounds, insect damage, and poor sanitation around infected plant material can favor the spread of bacterial diseases.',
    ),

    'Cutting Weevil': DiseaseInfo(
      name: 'Cutting Weevil',
      description: 'Cutting weevil damage is associated with insect feeding and cutting activity that can injure mango leaves and young plant tissues.',
      causes: 'The damage is caused by weevil activity, where the insect feeds on or cuts plant tissue.',
      whyItMightAppear: 'This leaf might have cutting weevil damage because feeding or cutting activity can leave visible injuries, missing sections, or damaged areas on the leaf.',
      contributingConditions: 'The presence of weevils, nearby infested plant material, and conditions that support insect activity can increase the likelihood of damage.',
    ),

    'Die Back': DiseaseInfo(
      name: 'Die Back',
      description: 'Die back is a condition in which parts of a mango plant gradually lose vitality and begin to dry or die. Symptoms can include browning, drying, and declining plant tissue.',
      causes: 'Die back can be associated with fungal pathogens, plant stress, wounds, and unfavorable growing conditions.',
      whyItMightAppear: 'This leaf might show signs associated with die back when the plant is experiencing disease, stress, or damage that interferes with normal growth and movement of water and nutrients.',
      contributingConditions: 'Drought stress, wounds, poor plant health, fungal infection, nutrient problems, and unfavorable environmental conditions may contribute to die back.',
    ),

    'Gall Midge': DiseaseInfo(
      name: 'Gall Midge',
      description: 'Gall midge damage is caused by small insects whose feeding or activity can produce abnormal growth, distortion, or damage on young mango tissues.',
      causes: 'The condition is associated with gall midge insects that can affect developing plant tissues.',
      whyItMightAppear: 'This leaf might have gall midge damage because insect activity during leaf development can interfere with normal tissue growth and produce visible abnormalities.',
      contributingConditions: 'The presence of gall midges, vulnerable young leaves, and environmental conditions that support insect activity can contribute to the problem.',
    ),

    'Healthy': DiseaseInfo(
      name: 'Healthy',
      description: 'A healthy mango leaf shows no strong visual signs associated with the diseases included in the EXOCARP detection model.',
      causes: 'Healthy leaves are not showing the disease patterns that EXOCARP was trained to recognize.',
      whyItMightAppear: 'EXOCARP may classify this leaf as healthy because its visible characteristics are more consistent with the healthy mango leaf examples used during model training.',
      contributingConditions: 'Good plant care, suitable growing conditions, adequate water and nutrients, and reduced exposure to pests and pathogens can support healthy leaf development.',
    ),

    'Powdery Mildew': DiseaseInfo(
      name: 'Powdery Mildew',
      description: 'Powdery mildew is a fungal disease that can produce a white or powder-like growth on plant surfaces. It can affect young mango leaves and other developing tissues.',
      causes: 'It is caused by powdery mildew fungi. The disease can develop under environmental conditions that favor fungal growth.',
      whyItMightAppear: 'This leaf might have powdery mildew if fungal growth has developed on its surface, potentially producing characteristic pale or powdery areas.',
      contributingConditions: 'Moderate temperatures, humid conditions, limited air circulation, and dense plant growth can contribute to powdery mildew development.',
    ),

    'Sooty Mould': DiseaseInfo(
      name: 'Sooty Mould',
      description: 'Sooty mould is a dark fungal growth that commonly develops on plant surfaces covered with honeydew produced by certain sap-feeding insects.',
      causes: 'The mould grows on honeydew deposited by insects such as aphids, scale insects, or other sap-feeding insects. The mould itself does not usually begin by directly infecting healthy leaf tissue.',
      whyItMightAppear: 'This leaf might have sooty mould because sap-feeding insects may have been present and produced honeydew on the leaf surface, allowing dark fungal growth to develop.',
      contributingConditions: 'Aphids, scale insects, mealybugs, high insect activity, and the accumulation of honeydew on leaves can contribute to sooty mould development.',
    ),
  };

  static DiseaseInfo? getInfo(String disease) {
    return _diseases[disease];
  }
}
